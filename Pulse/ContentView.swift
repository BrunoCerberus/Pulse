import SwiftUI

enum AppTab {
    case home
    case forYou
    case categories
    case bookmarks
    case search
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @StateObject private var themeManager = ThemeManager.shared

    private let serviceLocator: ServiceLocator

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "newspaper", value: .home) {
                HomeCoordinator.start(serviceLocator: serviceLocator)
            }

            Tab("For You", systemImage: "heart.text.square", value: .forYou) {
                ForYouCoordinator.start(serviceLocator: serviceLocator)
            }

            Tab("Categories", systemImage: "square.grid.2x2", value: .categories) {
                CategoriesCoordinator.start(serviceLocator: serviceLocator)
            }

            Tab("Bookmarks", systemImage: "bookmark", value: .bookmarks) {
                BookmarksCoordinator.start(serviceLocator: serviceLocator)
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                SearchCoordinator.start(serviceLocator: serviceLocator)
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .preferredColorScheme(themeManager.colorScheme)
        .onReceive(DeeplinkManager.shared.deeplinkPublisher) { deeplink in
            handleDeeplink(deeplink)
        }
    }

    private func handleDeeplink(_ deeplink: Deeplink) {
        switch deeplink {
        case .home:
            selectedTab = .home
        case .search:
            selectedTab = .search
        case .bookmarks:
            selectedTab = .bookmarks
        case .settings:
            // Settings is now accessed from Home, not TabView
            selectedTab = .home
        case .article:
            selectedTab = .home
        case .category:
            selectedTab = .categories
        }
    }
}
