import Combine
import EntropyCore
import Foundation

/// Routes deeplinks to coordinator navigation actions.
///
/// This class listens for deeplinks from the DeeplinkManager and coordinator
/// availability notifications, then routes navigation through the coordinator.
@MainActor
final class DeeplinkRouter {
    /// Weak reference to the coordinator for navigation
    private weak var coordinator: Coordinator?

    /// Subscription storage for long-lived observers
    private var cancellables = Set<AnyCancellable>()

    /// Cancellable for current article fetch request (one at a time)
    private var articleFetchCancellable: AnyCancellable?

    /// FIFO buffer of deeplinks received before the coordinator was available
    /// or while App Lock was engaged. A single optional slot would drop the
    /// first of two deeplinks arriving back-to-back (e.g. a cold-launch Quick
    /// Action followed by a `pulse://shared`); the queue preserves all of them
    /// in arrival order and drains them once routing is unblocked.
    private var queuedDeeplinks: [Deeplink] = []

    init() {
        setupObservers()
    }

    // AnyCancellable auto-cancels on deallocation; no explicit deinit needed.

    /// Sets the coordinator directly (used for testing).
    /// - Parameter coordinator: The coordinator to use for navigation
    func setCoordinator(_ coordinator: Coordinator) {
        self.coordinator = coordinator
        processQueuedDeeplink()
    }

    /// Sets up observers for coordinator availability and deeplinks.
    private func setupObservers() {
        // Listen for coordinator availability
        NotificationCenter.default.publisher(for: .coordinatorDidBecomeAvailable)
            .compactMap { $0.object as? Coordinator }
            .sink { [weak self] coordinator in
                guard let self else { return }
                Task { @MainActor in
                    self.coordinator = coordinator
                    self.processQueuedDeeplink()
                }
            }
            .store(in: &cancellables)

        // Listen for deeplinks
        DeeplinkManager.shared.deeplinkPublisher
            .sink { [weak self] deeplink in
                guard let self else { return }
                Task { @MainActor in
                    self.route(deeplink: deeplink)
                }
            }
            .store(in: &cancellables)

        // Flush any queued deeplinks the moment App Lock is unlocked. Quick
        // Actions, push payloads, and `pulse://` launches that arrive while
        // the app is locked are held in `queuedDeeplinks` and routed only
        // after the user authenticates — so the lock screen stays the only
        // visible surface until biometry / passcode succeeds.
        AppLockManager.shared.$isLocked
            .removeDuplicates()
            .sink { [weak self] isLocked in
                guard let self, !isLocked else { return }
                Task { @MainActor in
                    self.processQueuedDeeplink()
                }
            }
            .store(in: &cancellables)
    }

    /// Processes any deeplinks queued before the coordinator was available or
    /// while App Lock was engaged. Drains the whole buffer in arrival order.
    ///
    /// The buffer is cleared up front so that if `route` re-queues an entry
    /// (still locked / no coordinator) it lands in a fresh buffer rather than
    /// being re-drained in this same pass — preserving idempotency.
    private func processQueuedDeeplink() {
        guard !queuedDeeplinks.isEmpty else { return }
        let pending = queuedDeeplinks
        queuedDeeplinks.removeAll()
        for deeplink in pending {
            route(deeplink: deeplink)
        }
    }

    /// Routes a deeplink to the appropriate navigation action.
    ///
    /// Acts as a security gate: if App Lock is engaged the deeplink is held
    /// until the user authenticates, so a Quick Action / push notification /
    /// `pulse://` launch can never reveal its target screen behind the lock
    /// overlay. Real routing lives in `performRoute(deeplink:)`.
    ///
    /// - Parameter deeplink: The deeplink to route
    func route(deeplink: Deeplink) {
        if AppLockManager.shared.isLocked {
            queuedDeeplinks.append(deeplink)
            return
        }
        performRoute(deeplink: deeplink)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func performRoute(deeplink: Deeplink) {
        guard let coordinator else {
            // Queue the deeplink for later processing
            queuedDeeplinks.append(deeplink)
            return
        }

        switch deeplink {
        case .home:
            coordinator.switchTab(to: .home, popToRoot: true)

        case let .media(type):
            routeToMedia(type: type, coordinator: coordinator)

        case let .search(query):
            routeToSearch(query: query, coordinator: coordinator)

        case .bookmarks:
            coordinator.switchTab(to: .bookmarks, popToRoot: true)

        case .feed:
            coordinator.switchTab(to: .feed, popToRoot: true)

        case .briefing:
            coordinator.switchTab(to: .feed, popToRoot: true)
            coordinator.feedViewModel.handle(event: .onMorningBriefingTapped)

        case .settings:
            coordinator.switchTab(to: .home, popToRoot: true)
            coordinator.push(page: .settings)

        case let .article(id):
            // Fetch the article by ID and navigate to article detail
            coordinator.switchTab(to: .home, popToRoot: true)
            fetchAndNavigateToArticle(id: id, coordinator: coordinator)

        case .category:
            // Categories feature has been removed
            // Category deeplinks now navigate to home tab
            coordinator.switchTab(to: .home, popToRoot: true)

        case .sharedURLs:
            // The Share Extension has queued URLs in the App Group container.
            // Ask the import service to drain them so any subscribers (e.g. the
            // ArticleDetail summarization flow) can react.
            drainSharedURLQueue(coordinator: coordinator)
        }

        // Clear the deeplink after processing
        DeeplinkManager.shared.clearDeeplink()
    }

    /// Triggers the registered `SharedURLImportService` to drain its queue.
    /// Logs and silently no-ops if the service isn't registered (e.g. early
    /// debug builds before the import service shipped).
    private func drainSharedURLQueue(coordinator: Coordinator) {
        guard let importService = try? coordinator.serviceLocator.retrieve(SharedURLImportService.self) else {
            Logger.shared.warning(
                "SharedURLImportService not registered — pulse://shared dropped",
                category: "Navigation"
            )
            return
        }
        importService.processPendingItems()
    }

    private func routeToMedia(type: MediaType?, coordinator: Coordinator) {
        coordinator.switchTab(to: .media, popToRoot: true)
        if let type {
            coordinator.mediaViewModel.handle(event: .onMediaTypeSelected(type))
        }
    }

    private func routeToSearch(query: String?, coordinator: Coordinator) {
        coordinator.switchTab(to: .search, popToRoot: true)
        if let query, !query.isEmpty {
            coordinator.searchViewModel.handle(event: .onQueryChanged(query))
            coordinator.searchViewModel.handle(event: .onSearch)
        }
    }

    /// Fetches an article by ID and navigates to its detail view.
    /// - Parameters:
    ///   - id: The article ID (Guardian content path)
    ///   - coordinator: The coordinator to use for navigation
    private func fetchAndNavigateToArticle(id: String, coordinator: Coordinator) {
        guard let newsService = try? coordinator.serviceLocator.retrieve(NewsService.self) else {
            Logger.shared.error("Failed to retrieve NewsService for article deeplink", category: "Navigation")
            return
        }

        // Cancel any previous fetch to prevent memory accumulation
        articleFetchCancellable?.cancel()

        articleFetchCancellable = newsService.fetchArticle(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    // Clear the cancellable after completion to free memory
                    self?.articleFetchCancellable = nil

                    if case let .failure(error) = completion {
                        Logger.shared.error(
                            "Failed to fetch article \(id): \(error.localizedDescription)",
                            category: "Navigation"
                        )
                    }
                },
                receiveValue: { [weak coordinator] article in
                    Logger.shared.debug("Successfully fetched article: \(article.title)", category: "Navigation")
                    coordinator?.push(page: .articleDetail(article))
                }
            )
    }
}
