import EntropyCore
import Foundation

extension SmartBriefingDomainInteractor {
    // swiftlint:disable function_body_length

    /// Builds a personalized queue of unread articles and hands it straight
    /// to the global playback queue — no digest text, no `.digest` item.
    /// Falls back to widening the scope to `.allUnread` when the default
    /// "since last briefing" scope yields nothing, so the button almost
    /// always produces audio (mirrors `FeedDomainInteractor.startAudioBriefing()`'s
    /// "always produces audio" guarantee).
    ///
    /// - Note: Length is inherent to the do/catch scoring flow (fetch pool,
    ///   score, widen-on-empty, persist, dispatch) — kept as one Task body
    ///   rather than split, since the pieces share too much local state
    ///   (`lastServed`, `topN`, boxed services) to factor out cleanly.
    func startBriefing(scope: SmartBriefingScope) {
        // Defense-in-depth: re-verify Premium at the service boundary. The UI
        // entry point already hides the card entirely for non-premium users
        // (`isVisible` in `SmartBriefingViewState`), but a tampered client
        // could dispatch this action directly.
        guard storeKitService?.isPremium != false else {
            Logger.shared.service(
                "Smart Briefing blocked: Premium entitlement not active",
                level: .warning
            )
            return
        }
        guard let playbackQueueService else { return }

        buildTask?.cancel()
        updateState { $0.buildState = .building }

        let newsBox = UncheckedSendableBox(value: newsService)
        let forYouBox = UncheckedSendableBox(value: forYouService)
        let playbackBox = UncheckedSendableBox(value: playbackQueueService)
        let cacheBox = smartBriefingCacheService.map { UncheckedSendableBox(value: $0) }
        let settingsBox = settingsService.map { UncheckedSendableBox(value: $0) }

        buildTask = Task { @MainActor [weak self] in
            let language = AppLocalization.shared.language

            let pool = await FeedArticlePoolBuilder
                .fetchPool(newsService: newsBox.value, language: language)
                .filter { !$0.isMedia }
            guard !Task.isCancelled else { return }

            let lastServed = cacheBox?.value.fetchLastServed()
            let topN = await settingsBox?.value.fetchPreferencesOnce()?.morningBriefingArticleCount ?? 12

            do {
                var scored: [ScoredArticle] = []
                if let forYouService = forYouBox.value {
                    let scopedPool = SmartBriefingQueueBuilder.filterPool(
                        pool,
                        scope: scope,
                        lastServedAt: scope == .unreadSinceLastBriefing ? lastServed?.servedAt : nil,
                        servedArticleIDs: lastServed?.servedArticleIDs ?? []
                    )
                    scored = try await forYouService.scoredArticles(from: scopedPool, topN: topN)

                    // Never show an empty queue just because the "since last
                    // briefing" scope filtered everything out — widen to all
                    // unread (still excluding previously served IDs) before giving up.
                    if scored.isEmpty, scope == .unreadSinceLastBriefing {
                        let widenedPool = SmartBriefingQueueBuilder.filterPool(
                            pool,
                            scope: .allUnread,
                            lastServedAt: nil,
                            servedArticleIDs: lastServed?.servedArticleIDs ?? []
                        )
                        scored = try await forYouService.scoredArticles(from: widenedPool, topN: topN)
                    }
                }

                guard self != nil, !Task.isCancelled else { return }

                guard !scored.isEmpty else {
                    // Nothing was actually served — leave the cache's
                    // last-served timestamp untouched rather than advancing
                    // it to `.now`, so the UI's "last briefed" label doesn't
                    // diverge from what the cache will report on relaunch.
                    self?.dispatch(action: .buildSucceeded(itemCount: 0, servedAt: lastServed?.servedAt))
                    return
                }

                let items = scored.map { PlaybackItem.briefingArticle($0.article, language: language) }
                playbackBox.value.play(items: items, mode: .briefing)

                let servedIDs = Set(scored.map { $0.article.id })
                let record = SmartBriefingServedRecord(
                    servedAt: .now,
                    servedArticleIDs: (lastServed?.servedArticleIDs ?? []).union(servedIDs)
                )
                cacheBox?.value.store(record)

                self?.analyticsService?.logEvent(.smartBriefingStarted(itemCount: items.count))
                self?.dispatch(action: .buildSucceeded(itemCount: items.count, servedAt: record.servedAt))
            } catch {
                guard !Task.isCancelled else { return }
                Logger.shared.error(
                    "Smart Briefing scoring failed: \(error)",
                    category: "SmartBriefingDomainInteractor"
                )
                self?.dispatch(action: .buildFailed(error.localizedDescription))
            }
        }
    }

    // swiftlint:enable function_body_length
}
