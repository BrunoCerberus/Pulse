import UIKit
import SwiftUI

final class PulseSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        registerServices()

        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = UIHostingController(rootView: ContentView())
        window?.makeKeyAndVisible()

        if let urlContext = connectionOptions.urlContexts.first {
            handleDeeplink(urlContext.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleDeeplink(url)
    }

    private func registerServices() {
        ServiceLocator.shared.register(StorageService.self, service: LiveStorageService())
        ServiceLocator.shared.register(NewsService.self, service: LiveNewsService())
        ServiceLocator.shared.register(SearchService.self, service: LiveSearchService())
        ServiceLocator.shared.register(BookmarksService.self, service: LiveBookmarksService())
        ServiceLocator.shared.register(SettingsService.self, service: LiveSettingsService())
        ServiceLocator.shared.register(CategoriesService.self, service: LiveCategoriesService())
        ServiceLocator.shared.register(ForYouService.self, service: LiveForYouService())
    }

    private func handleDeeplink(_ url: URL) {
        DeeplinkManager.shared.parse(url: url)
    }
}
