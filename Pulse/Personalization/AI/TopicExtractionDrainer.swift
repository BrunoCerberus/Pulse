import EntropyCore
import Foundation
import UIKit

/// Drains queued `EngagementEvent`s into the `InterestProfileService` by
/// running on-device topic extraction.
///
/// ## When it fires
///
/// On `UIApplication.didEnterBackgroundNotification`. Background time is
/// the right moment because:
/// 1. The user isn't actively waiting on UI (LLM calls are 200–500 ms each)
/// 2. We're competing less for the single LLM thread (no foreground
///    Daily Digest / Summarization in flight)
/// 3. iOS gives us a few seconds of background runtime before suspending
///
/// ## Safety properties
///
/// - **No concurrent runs.** A second background notification while a drain
///   is in progress is coalesced — the running task finishes first.
/// - **Sequential extraction only.** llama.cpp is single-threaded; the
///   `for event in pending` loop awaits each call.
/// - **Memory-pressure aware.** `LLMError.memoryPressure` aborts the batch
///   immediately; remaining events stay queued for a later attempt.
/// - **Best-effort, never disruptive.** Every failure path is logged and
///   swallowed; the drain never throws.
@MainActor
final class TopicExtractionDrainer {
    private let engagementService: EngagementEventsService
    private let extractionService: TopicExtractionService
    private let profileService: InterestProfileService

    /// `nonisolated(unsafe)` so `deinit` (which is non-isolated) can read it
    /// to call `NotificationCenter.removeObserver`. We only assign on the
    /// main actor (via `startObservingBackground`) and only read on main
    /// actor outside `deinit`, so this is safe in practice.
    private nonisolated(unsafe) var observer: NSObjectProtocol?
    private var currentDrainTask: Task<Void, Never>?

    init(
        engagementService: EngagementEventsService,
        extractionService: TopicExtractionService,
        profileService: InterestProfileService
    ) {
        self.engagementService = engagementService
        self.extractionService = extractionService
        self.profileService = profileService
    }

    /// Begins observing `didEnterBackgroundNotification`. Idempotent — calling
    /// twice is harmless (the second call is a no-op).
    func startObservingBackground() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Hop to MainActor (the notification queue is already main, but
            // the closure isn't isolated — explicit hop satisfies the type
            // checker without the need for `MainActor.assumeIsolated`).
            Task { @MainActor [weak self] in
                self?.kickOffDrain()
            }
        }
    }

    /// Triggers a drain right now. Mostly useful in tests; production code
    /// goes through `startObservingBackground()`.
    func drainNow(batchSize: Int = 20) async {
        await performDrainCoalesced(batchSize: batchSize)
    }

    private func kickOffDrain(batchSize: Int = 20) {
        Task { @MainActor [weak self] in
            await self?.performDrainCoalesced(batchSize: batchSize)
        }
    }

    private func performDrainCoalesced(batchSize: Int) async {
        if let currentDrainTask, !currentDrainTask.isCancelled {
            await currentDrainTask.value
            return
        }
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performDrain(batchSize: batchSize)
        }
        currentDrainTask = task
        await task.value
        currentDrainTask = nil
    }

    private func performDrain(batchSize: Int) async {
        // Box every service before the first await — the protocols aren't
        // declared `Sendable`, and Swift 6 strict concurrency conservatively
        // flags any non-Sendable receiver of an async call as a potential
        // race. Same convention as `LiveBookmarksService`.
        let engagement = UncheckedSendableBox(value: engagementService)
        let extraction = UncheckedSendableBox(value: extractionService)
        let profile = UncheckedSendableBox(value: profileService)

        let pending: [EngagementEvent]
        do {
            pending = try await engagement.value.pendingEvents(limit: batchSize)
        } catch {
            Logger.shared.service(
                "TopicExtractionDrainer: failed to fetch pending events: \(error)",
                level: .warning
            )
            return
        }
        guard !pending.isEmpty else { return }

        guard extraction.value.isModelAvailable else {
            // Don't force-load the 600 MB model just for personalization —
            // wait until another premium feature has paid the load cost,
            // then drain on the next background notification.
            Logger.shared.service(
                "TopicExtractionDrainer: model not loaded, deferring \(pending.count) event(s)",
                level: .debug
            )
            return
        }

        var processedIDs: [UUID] = []
        for event in pending {
            if Task.isCancelled { break }
            do {
                let tags = try await extraction.value.extractTopics(
                    title: event.articleTitle,
                    summary: event.articleSummary
                )
                await applyTags(tags, for: event, profile: profile)
                processedIDs.append(event.id)
            } catch let error as LLMError where error == .memoryPressure {
                // Stop the batch but DON'T mark anything processed —
                // memory pressure is transient.
                Logger.shared.service(
                    "TopicExtractionDrainer: memory pressure, stopping batch",
                    level: .warning
                )
                break
            } catch {
                // Other errors: log, mark processed (so we don't loop on
                // the same poison-pill event forever), continue.
                Logger.shared.service(
                    "TopicExtractionDrainer: extraction failed for \(event.articleID): \(error)",
                    level: .debug
                )
                processedIDs.append(event.id)
            }
        }

        if !processedIDs.isEmpty {
            do {
                try await engagement.value.markProcessed(processedIDs)
            } catch {
                Logger.shared.service(
                    "TopicExtractionDrainer: markProcessed failed: \(error)",
                    level: .warning
                )
            }
        }
    }

    private func applyTags(
        _ tags: [String],
        for event: EngagementEvent,
        profile: UncheckedSendableBox<InterestProfileService>
    ) async {
        guard !tags.isEmpty else { return }
        let perTagWeight = event.weight / Double(tags.count)
        for tag in tags {
            try? await profile.value.upsert(
                topicID: tag,
                displayName: TopicExtractionPromptBuilder.displayName(for: tag),
                weightDelta: perTagWeight,
                source: .extracted,
                category: event.categoryRaw
            )
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
