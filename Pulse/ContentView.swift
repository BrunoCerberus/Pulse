import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeCoordinator.start()
                .tabItem {
                    Label(Tab.home.title, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)

            ForYouCoordinator.start()
                .tabItem {
                    Label(Tab.forYou.title, systemImage: Tab.forYou.icon)
                }
                .tag(Tab.forYou)

            CategoriesCoordinator.start()
                .tabItem {
                    Label(Tab.categories.title, systemImage: Tab.categories.icon)
                }
                .tag(Tab.categories)

            SearchCoordinator.start()
                .tabItem {
                    Label(Tab.search.title, systemImage: Tab.search.icon)
                }
                .tag(Tab.search)

            BookmarksCoordinator.start()
                .tabItem {
                    Label(Tab.bookmarks.title, systemImage: Tab.bookmarks.icon)
                }
                .tag(Tab.bookmarks)

            SettingsCoordinator.start()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
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
            selectedTab = .settings
        case .article:
            selectedTab = .home
        case .category:
            selectedTab = .categories
        }
    }
}

enum Tab: String, CaseIterable {
    case home
    case forYou
    case categories
    case search
    case bookmarks
    case settings

    var title: String {
        switch self {
        case .home: return String(localized: "Home")
        case .forYou: return String(localized: "For You")
        case .categories: return String(localized: "Categories")
        case .search: return String(localized: "Search")
        case .bookmarks: return String(localized: "Bookmarks")
        case .settings: return String(localized: "Settings")
        }
    }

    var icon: String {
        switch self {
        case .home: return "newspaper"
        case .forYou: return "heart.text.square"
        case .categories: return "square.grid.2x2"
        case .search: return "magnifyingglass"
        case .bookmarks: return "bookmark"
        case .settings: return "gearshape"
        }
    }
}

#Preview {
    ContentView()
}
