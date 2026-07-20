import Combine
import EntropyCore
import Foundation

/// Opportunistically pre-generates today's Morning Briefing while the app is
/// foregrounded, so tapping the scheduled notification later that day can
/// start playback instantly instead of waiting on a fresh LLM generation.
///
/// Modeled on `TopicExtractionDrainer`: best-effort, silent on every failure
/// path (including the LLM's single-generation `.busy` gate), never
/// surfaces anything to the user.
@MainActor
final class MorningBriefingPrefetcher {
    private let feedService: FeedService
    private let newsService: NewsService
    private let forYouService: ForYouService?
    private let settingsService: SettingsService
    private let briefingCacheService: BriefingCacheService
    private let notificationService: NotificationService?
    private let storeKitService: StoreKitService?

    private var prefetchTask: Task<Void, Never>?

    init(
        feedService: FeedService,
        newsService: NewsService,
        forYouService: ForYouService?,
        settingsService: SettingsService,
        briefingCacheService: BriefingCacheService,
        notificationService: NotificationService?,
        storeKitService: StoreKitService?,
    ) {
        self.feedService = feedService
        self.newsService = newsService
        self.forYouService = forYouService
        self.settingsService = settingsService
        self.briefingCacheService = briefingCacheService
        self.notificationService = notificationService
        self.storeKitService = storeKitService
    }

    /// Call on every foreground activation. Every guard failure is a silent
    /// no-op — this is a background nicety, never a user-facing flow. A
    /// prefetch already in flight is left to finish; a redundant kick is
    /// simply dropped (foreground activations are infrequent enough that
    /// this is fine, unlike `TopicExtractionDrainer`'s rerun-coalescing).
    func prefetchIfNeeded() {
        guard prefetchTask == nil else { return }
        prefetchTask = Task { @MainActor [weak self] in
            await self?.run()
            self?.prefetchTask = nil
        }
    }

    // swiftlint:disable:next function_body_length
    private func run() async {
        // Absence of a registered StoreKitService (previews / unit tests)
        // doesn't gate — matches the `!= false` convention used by
        // `FeedDomainInteractor`/`SettingsDomainInteractor`. An explicit
        // non-premium reading self-heals a stale enabled preference.
        if let storeKitService, !storeKitService.isPremium {
            await selfHealIfDowngraded()
            return
        }

        guard let preferences = await fetchPreferences(), preferences.morningBriefingEnabled else {
            return
        }

        guard isBeforeScheduledTime(
            hour: preferences.morningBriefingHour,
            minute: preferences.morningBriefingMinute,
        ) else {
            return
        }

        guard briefingCacheService.fetchIfFreshToday() == nil else { return }

        let newsServiceBox = UncheckedSendableBox(value: newsService)
        let pool = await FeedArticlePoolBuilder.fetchPool(
            newsService: newsServiceBox.value,
            language: AppLocalization.shared.language,
        )
        guard !pool.isEmpty else { return }

        let articlesToProcess = FeedDigestPromptBuilder.cappedArticles(from: pool)
        let feedServiceBox = UncheckedSendableBox(value: feedService)

        do {
            try await feedServiceBox.value.loadModelIfNeeded()

            var fullText = ""
            for try await token in feedServiceBox.value.generateDigest(from: articlesToProcess) {
                fullText += token
            }

            let summary = FeedDomainInteractor.cleanLLMOutput(fullText)
            guard !summary.isEmpty else { return }

            let digest = DailyDigest(
                id: UUID().uuidString,
                summary: summary,
                sourceArticles: articlesToProcess,
                generatedAt: .now,
            )

            var queueArticles: [Article] = []
            if let forYouService {
                let forYouBox = UncheckedSendableBox(value: forYouService)
                let nonMediaPool = pool.filter { !$0.isMedia }
                let scored = await (try? forYouBox.value.scoredArticles(
                    from: nonMediaPool,
                    topN: preferences.morningBriefingArticleCount,
                )) ?? []
                queueArticles = scored.map(\.article)
            }

            briefingCacheService.store(
                PregeneratedBriefing(digest: digest, queueArticles: queueArticles, generatedAt: .now),
            )
        } catch {
            // Every generation error — including LLMError.busy from the
            // shared single-generation gate — is treated the same way:
            // skip silently, try again on the next foreground activation.
            Logger.shared.service(
                "MorningBriefingPrefetcher: generation skipped (\(error))",
                level: .debug,
            )
        }
    }

    private func isBeforeScheduledTime(hour: Int, minute: Int) -> Bool {
        let now = Date()
        guard let scheduled = Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: now,
        ) else {
            return false
        }
        return now < scheduled
    }

    /// If Premium lapsed while the preference is still enabled, cancel the
    /// pending notification so a non-premium user doesn't keep getting a
    /// daily reminder for a feature they no longer have access to.
    private func selfHealIfDowngraded() async {
        guard let preferences = await fetchPreferences(), preferences.morningBriefingEnabled else { return }
        notificationService?.cancelMorningBriefingNotification()
    }

    private func fetchPreferences() async -> UserPreferences? {
        let service = UncheckedSendableBox(value: settingsService)
        return await service.value.fetchPreferencesOnce()
    }
}
