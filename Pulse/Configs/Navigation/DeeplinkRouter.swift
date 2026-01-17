import Combine
import Foundation

/// Routes deeplinks to coordinator navigation actions.
///
/// This class listens for deeplinks from the DeeplinkManager and coordinator
/// availability notifications, then routes navigation through the coordinator.
@MainActor
final class DeeplinkRouter {
    /// Weak reference to the coordinator for navigation
    private weak var coordinator: Coordinator?

    /// Subscription storage
    private var cancellables = Set<AnyCancellable>()

    /// Queued deeplink to process when coordinator becomes available
    private var queuedDeeplink: Deeplink?

    init() {
        setupObservers()
    }

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
    }

    /// Processes any queued deeplink that was received before coordinator was available.
    private func processQueuedDeeplink() {
        guard let deeplink = queuedDeeplink else { return }
        queuedDeeplink = nil
        route(deeplink: deeplink)
    }

    /// Routes a deeplink to the appropriate navigation action.
    /// - Parameter deeplink: The deeplink to route
    func route(deeplink: Deeplink) {
        guard let coordinator else {
            // Queue the deeplink for later processing
            queuedDeeplink = deeplink
            return
        }

        switch deeplink {
        case .home:
            coordinator.switchTab(to: .home, popToRoot: true)

        case .forYou:
            coordinator.switchTab(to: .forYou, popToRoot: true)

        case let .search(query):
            coordinator.switchTab(to: .search, popToRoot: true)
            if let query, !query.isEmpty {
                // Update the search view model with the query
                coordinator.searchViewModel.handle(event: .onQueryChanged(query))
                coordinator.searchViewModel.handle(event: .onSearch)
            }

        case .bookmarks:
            coordinator.switchTab(to: .bookmarks, popToRoot: true)

        case .feed:
            coordinator.switchTab(to: .feed, popToRoot: true)

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
        }

        // Clear the deeplink after processing
        DeeplinkManager.shared.clearDeeplink()
    }

    /// Fetches an article by ID and navigates to its detail view.
    /// - Parameters:
    ///   - id: The article ID (Guardian content path)
    ///   - coordinator: The coordinator to use for navigation
    private func fetchAndNavigateToArticle(id: String, coordinator: Coordinator) {
        guard let newsService = try? coordinator.serviceLocator.retrieve(NewsService.self) else {
            debugPrint("DeeplinkRouter: Failed to retrieve NewsService for article deeplink")
            return
        }

        newsService.fetchArticle(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        debugPrint("DeeplinkRouter: Failed to fetch article \(id): \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak coordinator] article in
                    coordinator?.push(page: .articleDetail(article))
                }
            )
            .store(in: &cancellables)
    }
}
