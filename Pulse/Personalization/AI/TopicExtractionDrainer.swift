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
    /// Set when a kick arrives while a drain is already in flight (M4). The
    /// running coalescer loops once more after the current pass so events
    /// enqueued mid-drain still get processed instead of waiting for the next
    /// backgrounding.
    private var rerunRequested = false

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
        // A drain is already running: request one more pass so events enqueued
        // while it runs get processed (M4), then await the in-flight task. The
        // owning runner below picks up `rerunRequested` and loops.
        if let currentDrainTask, !currentDrainTask.isCancelled {
            rerunRequested = true
            await currentDrainTask.value
            return
        }
        let task = Task { [weak self] in
            guard let self else { return }
            // Loop while a kick arrived mid-drain. Reset the flag *before* each
            // pass so only kicks that land during/after that pass trigger a
            // rerun (and a kick during the final `performDrain` is still seen
            // by the `while`). Cancellation / memory-pressure stop conditions
            // inside `performDrain` still apply per pass — both leave the queue
            // intact for a later attempt.
            repeat {
                self.rerunRequested = false
                await self.performDrain(batchSize: batchSize)
            } while self.rerunRequested && !Task.isCancelled
        }
        currentDrainTask = task
        await task.value
        // Clear ownership but DON'T reset `rerunRequested` here: a kick that
        // landed in the gap between the task's final `while` exit and this
        // continuation resuming must not be lost. Leaving the flag set means
        // the next `performDrainCoalesced` (or the check below) still drains
        // those events.
        currentDrainTask = nil
        if rerunRequested, !Task.isCancelled {
            await performDrainCoalesced(batchSize: batchSize)
        }
    }

    // swiftlint:disable:next function_body_length
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

        // Mark each event processed *inside* the loop, BEFORE applying its
        // tags (M5). Removing the event from the durable queue first means a
        // `markProcessed` failure costs us one signal rather than re-applying
        // that event's additive weight on every future drain (unbounded
        // inflation). For best-effort personalization, "lose one signal" beats
        // "double-count forever". Per-event (vs. batched at end-of-drain) keeps
        // any single failure from forfeiting the whole batch.
        for event in pending {
            if Task.isCancelled { break }
            do {
                let tags = try await extraction.value.extractTopics(
                    title: event.articleTitle,
                    summary: event.articleSummary
                )
                do {
                    try await engagement.value.markProcessed([event.id])
                    await applyTags(tags, for: event, profile: profile)
                } catch {
                    Logger.shared.service(
                        "TopicExtractionDrainer: markProcessed failed for \(event.articleID); skipping apply: \(error)",
                        level: .warning
                    )
                    break
                }
            } catch let error as LLMError where error == .memoryPressure || error == .busy {
                // Stop the batch and DON'T mark anything processed — both
                // memory pressure and a busy model (a foreground digest /
                // summarization holding the shared single-context LLM, H3) are
                // transient. Leaving the events queued lets the next background
                // drain retry them instead of dropping the engagement signal.
                Logger.shared.service(
                    "TopicExtractionDrainer: \(error == .busy ? "model busy" : "memory pressure"), stopping batch",
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
                try? await engagement.value.markProcessed([event.id])
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

        // Prefer the batched API so all of this event's tags land in a single
        // save + a single `.interestProfileDidChange` broadcast (M14) — one
        // `ForYou` rescore per event instead of one per tag. `upsertMany` is a
        // concrete affordance of `LiveInterestProfileService`; the protocol
        // can't expose it without an out-of-scope change, so fall back to the
        // per-tag protocol API for mocks / other implementations.
        if let live = profile.value as? LiveInterestProfileService {
            let upserts = tags.map { tag in
                InterestTopicUpsert(
                    topicID: tag,
                    displayName: TopicExtractionPromptBuilder.displayName(for: tag),
                    weightDelta: perTagWeight,
                    source: .extracted,
                    category: event.categoryRaw
                )
            }
            try? await live.upsertMany(upserts)
            return
        }

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
