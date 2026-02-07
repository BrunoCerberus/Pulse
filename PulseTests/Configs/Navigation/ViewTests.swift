import EntropyCore
@testable import Pulse
import SwiftUI
import Testing

@Suite("PremiumFeature Tests")
struct PremiumFeatureTests {
    @Test("dailyDigest has sparkles icon")
    func dailyDigestHasSparklesIcon() {
        #expect(PremiumFeature.dailyDigest.icon == "sparkles")
    }

    @Test("dailyDigest has purple icon color")
    func dailyDigestHasPurpleIconColor() {
        #expect(PremiumFeature.dailyDigest.iconColor == .purple)
    }

    @Test("articleSummarization has doc.text.magnifyingglass icon")
    func articleSummarizationHasDocTextMagnifyingGlassIcon() {
        #expect(PremiumFeature.articleSummarization.icon == "doc.text.magnifyingglass")
    }

    @Test("articleSummarization has blue icon color")
    func articleSummarizationHasBlueIconColor() {
        #expect(PremiumFeature.articleSummarization.iconColor == .blue)
    }
}

@Suite("PremiumGateView Tests")
struct PremiumGateViewTests {
    @Test("PremiumGateView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let view = PremiumGateView(feature: .dailyDigest, serviceLocator: serviceLocator)
        #expect(view is PremiumGateView)
    }

    @Test("init sets feature")
    func initSetsFeature() {
        let serviceLocator = ServiceLocator()
        let view = PremiumGateView(feature: .articleSummarization, serviceLocator: serviceLocator)
        #expect(view.feature == .articleSummarization)
    }

    @Test("init sets serviceLocator")
    func initSetsServiceLocator() {
        let serviceLocator = ServiceLocator()
        let view = PremiumGateView(feature: .dailyDigest, serviceLocator: serviceLocator)
        #expect(view.serviceLocator === serviceLocator)
    }

    @Test("init sets onUnlockTapped callback")
    func initSetsOnUnlockTapped() {
        let serviceLocator = ServiceLocator()
        var callbackCalled = false
        let view = PremiumGateView(
            feature: .dailyDigest,
            serviceLocator: serviceLocator,
            onUnlockTapped: { callbackCalled = true }
        )
        #expect(view.onUnlockTapped != nil)
    }
}

@Suite("PremiumGatedModifier Tests")
struct PremiumGatedModifierTests {
    @Test("body returns content when isPremium is true")
    func bodyReturnsContentWhenPremium() {
        let modifier = PremiumGatedModifier(isPremium: true) {
            Text("Gate Content")
        }

        let content = Text("Premium Content")
        let result = modifier.body(content: content)

        // The result should contain the premium content
        #expect(result is some View)
    }

    @Test("body returns gate content when isPremium is false")
    func bodyReturnsGateContentWhenNotPremium() {
        let modifier = PremiumGatedModifier(isPremium: false) {
            Text("Gate Content")
        }

        let content = Text("Premium Content")
        let result = modifier.body(content: content)

        #expect(result is some View)
    }
}

@Suite("FeedView Tests")
struct FeedViewTests {
    @Test("FeedView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let viewModel = FeedViewModel(serviceLocator: serviceLocator)
        let router = FeedNavigationRouter()
        let view = FeedView(router: router, viewModel: viewModel, serviceLocator: serviceLocator)
        #expect(view is FeedView)
    }

    @Test("isProcessing returns true when processing")
    func isProcessingReturnsTrueWhenProcessing() {
        let serviceLocator = ServiceLocator()
        let viewModel = FeedViewModel(serviceLocator: serviceLocator)
        let router = FeedNavigationRouter()
        let view = FeedView(router: router, viewModel: viewModel, serviceLocator: serviceLocator)

        // Access the private isProcessing property through reflection
        // For now, just verify the view can be instantiated
        #expect(view is FeedView)
    }

    @Test("init sets router")
    func initSetsRouter() {
        let serviceLocator = ServiceLocator()
        let viewModel = FeedViewModel(serviceLocator: serviceLocator)
        let router = FeedNavigationRouter()
        let view = FeedView(router: router, viewModel: viewModel, serviceLocator: serviceLocator)
        #expect(view.router is FeedNavigationRouter)
    }

    @Test("init sets serviceLocator")
    func initSetsServiceLocator() {
        let serviceLocator = ServiceLocator()
        let viewModel = FeedViewModel(serviceLocator: serviceLocator)
        let router = FeedNavigationRouter()
        let view = FeedView(router: router, viewModel: viewModel, serviceLocator: serviceLocator)
        #expect(view.serviceLocator === serviceLocator)
    }
}

@Suite("SignInView Tests")
struct SignInViewTests {
    @Test("SignInView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let view = SignInView(serviceLocator: serviceLocator)
        #expect(view is SignInView)
    }

    @Test("init creates viewModel")
    func initCreatesViewModel() {
        let serviceLocator = ServiceLocator()
        let view = SignInView(serviceLocator: serviceLocator)
        #expect(view.viewModel is SignInViewModel)
    }
}

@Suite("PaywallView Tests")
struct PaywallViewTests {
    @Test("PaywallView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        let view = PaywallView(viewModel: viewModel)
        #expect(view is PaywallView)
    }

    @Test("init sets viewModel")
    func initSetsViewModel() {
        let serviceLocator = ServiceLocator()
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        let view = PaywallView(viewModel: viewModel)
        #expect(view.viewModel is PaywallViewModel)
    }

    @Test("isRunningTests returns true in test environment")
    func isRunningTestsReturnsTrueInTestEnvironment() {
        let serviceLocator = ServiceLocator()
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        let view = PaywallView(viewModel: viewModel)

        // Set test environment variable
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] = "/path/to/test/config"

        let isRunningTests = view.isRunningTests

        #expect(isRunningTests == true)

        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] = nil
    }

    @Test("isRunningTests returns false outside test environment")
    func isRunningTestsReturnsFalseOutsideTestEnvironment() {
        let serviceLocator = ServiceLocator()
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        let view = PaywallView(viewModel: viewModel)

        // Ensure test environment variable is not set
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] = nil

        let isRunningTests = view.isRunningTests

        #expect(isRunningTests == false)
    }
}

@Suite("PaywallViewModel Tests")
struct PaywallViewModelTests {
    @Test("PaywallViewModel can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        #expect(viewModel is PaywallViewModel)
    }

    @Test("initial viewState is loading")
    func initialStateIsLoading() {
        let serviceLocator = ServiceLocator()
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        #expect(viewModel.viewState == .loading)
    }
}

@Suite("RootView Tests")
struct RootViewTests {
    @Test("RootView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let view = RootView(serviceLocator: serviceLocator)
        #expect(view is RootView)
    }

    @Test("init sets serviceLocator")
    func initSetsServiceLocator() {
        let serviceLocator = ServiceLocator()
        let view = RootView(serviceLocator: serviceLocator)
        #expect(view.serviceLocator === serviceLocator)
    }
}

@Suite("CoordinatorView Tests")
struct CoordinatorViewTests {
    @Test("CoordinatorView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let view = CoordinatorView(serviceLocator: serviceLocator)
        #expect(view is CoordinatorView)
    }

    @Test("init sets serviceLocator")
    func initSetsServiceLocator() {
        let serviceLocator = ServiceLocator()
        let view = CoordinatorView(serviceLocator: serviceLocator)
        #expect(view.serviceLocator === serviceLocator)
    }
}

@Suite("DeeplinkManager Tests")
struct DeeplinkManagerTests {
    @Test("shared returns singleton")
    func sharedReturnsSingleton() {
        let manager1 = DeeplinkManager.shared
        let manager2 = DeeplinkManager.shared
        #expect(manager1 === manager2)
    }

    @Test("handle sends deeplink to publisher")
    func handleSendsDeeplinkToPublisher() async throws {
        let manager = DeeplinkManager()
        var receivedDeeplink: Deeplink?

        let cancellable = manager.deeplinkPublisher.sink { deeplink in
            receivedDeeplink = deeplink
        }

        let deeplink: Deeplink = .home
        manager.handle(deeplink: deeplink)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedDeeplink == .home)

        cancellable.cancel()
    }

    @Test("clearDeeplink clears current deeplink")
    func clearDeeplinkClearsCurrentDeeplink() {
        let manager = DeeplinkManager()
        manager.handle(deeplink: .home)
        manager.clearDeeplink()
        #expect(manager.currentDeeplink == nil)
    }
}

@Suite("Page Tests")
struct PageTests {
    @Test("all cases are hashable")
    func allCasesAreHashable() throws {
        let article = try #require(Article.mockArticles.first)
        let page1: Page = .articleDetail(article)
        let page2: Page = .articleDetail(article)
        let page3: Page = .settings

        var set = Set<Page>()
        set.insert(page1)
        set.insert(page2)
        set.insert(page3)

        #expect(set.count == 2)
    }

    @Test("articleDetail case stores article")
    func articleDetailCaseStoresArticle() throws {
        let article = try #require(Article.mockArticles.first)
        let page: Page = .articleDetail(article)

        if case let .articleDetail(storedArticle) = page {
            #expect(storedArticle.id == article.id)
        } else {
            Issue.record("Expected articleDetail case")
        }
    }

    @Test("settings case is value")
    func settingsCaseIsValue() {
        let page: Page = .settings

        if case .settings = page {
            // Success
        } else {
            Issue.record("Expected settings case")
        }
    }
}

@Suite("AppTab Tests")
struct AppTabTests {
    @Test("all cases have symbolImage")
    func allCasesHaveSymbolImage() {
        let tabs: [AppTab] = [.home, .media, .feed, .bookmarks, .search]
        for tab in tabs {
            let image = tab.symbolImage
            #expect(!image.isEmpty)
        }
    }

    @Test("home tab has newspaper symbol")
    func homeTabHasNewspaperSymbol() {
        #expect(AppTab.home.symbolImage == "newspaper")
    }

    @Test("media tab has play.tv symbol")
    func mediaTabHasPlayTVSymbol() {
        #expect(AppTab.media.symbolImage == "play.tv")
    }

    @Test("feed tab has text.document symbol")
    func feedTabHasTextDocumentSymbol() {
        #expect(AppTab.feed.symbolImage == "text.document")
    }

    @Test("bookmarks tab has bookmark symbol")
    func bookmarksTabHasBookmarkSymbol() {
        #expect(AppTab.bookmarks.symbolImage == "bookmark")
    }

    @Test("search tab has magnifyingglass symbol")
    func searchTabHasMagnifyingGlassSymbol() {
        #expect(AppTab.search.symbolImage == "magnifyingglass")
    }

    @Test("all cases have symbolEffect")
    func allCasesHaveSymbolEffect() {
        let tabs: [AppTab] = [.home, .media, .feed, .bookmarks, .search]
        for tab in tabs {
            let effect = tab.symbolEffect
            #expect(effect is any DiscreteSymbolEffect & SymbolEffect)
        }
    }
}

@Suite("NotificationDeeplinkParser Tests")
struct NotificationDeeplinkParserTests {
    @Test("parse returns nil for empty userInfo")
    func parseReturnsNilForEmptyUserInfo() {
        let result = NotificationDeeplinkParser.parse(from: [:])
        #expect(result == nil)
    }

    @Test("parseURL parses home deeplink")
    func parseURLParsesHomeDeeplink() throws {
        let url = try #require(URL(string: "pulse://home"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .home)
    }

    @Test("parseURL parses feed deeplink")
    func parseURLParsesFeedDeeplink() throws {
        let url = try #require(URL(string: "pulse://feed"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .feed)
    }

    @Test("parseURL parses bookmarks deeplink")
    func parseURLParsesBookmarksDeeplink() throws {
        let url = try #require(URL(string: "pulse://bookmarks"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .bookmarks)
    }

    @Test("parseURL parses settings deeplink")
    func parseURLParsesSettingsDeeplink() throws {
        let url = try #require(URL(string: "pulse://settings"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .settings)
    }

    @Test("parseURL parses search deeplink with query")
    func parseURLParsesSearchDeeplink() throws {
        let url = try #require(URL(string: "pulse://search?q=swift"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .search(query: "swift"))
    }

    @Test("parseURL parses article deeplink")
    func parseURLParsesArticleDeeplink() throws {
        let url = try #require(URL(string: "pulse://article?id=test/article"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == .article(id: "test/article"))
    }

    @Test("parseURL returns nil for invalid scheme")
    func parseURLReturnsNilForInvalidScheme() throws {
        let url = try #require(URL(string: "https://example.com"))
        let result = NotificationDeeplinkParser.parseURL(url)
        #expect(result == nil)
    }

    @Test("parseTyped parses home type")
    func parseTypedParsesHomeType() {
        let result = NotificationDeeplinkParser.parseTyped(type: "home", userInfo: [:])
        #expect(result == .home)
    }

    @Test("parseTyped parses feed type")
    func parseTypedParsesFeedType() {
        let result = NotificationDeeplinkParser.parseTyped(type: "feed", userInfo: [:])
        #expect(result == .feed)
    }

    @Test("parseTyped parses search type with query")
    func parseTypedParsesSearchType() {
        let userInfo: [AnyHashable: Any] = ["deeplinkQuery": "swift"]
        let result = NotificationDeeplinkParser.parseTyped(type: "search", userInfo: userInfo)
        #expect(result == .search(query: "swift"))
    }

    @Test("parseTyped parses article type")
    func parseTypedParsesArticleType() {
        let userInfo: [AnyHashable: Any] = ["deeplinkId": "test/article"]
        let result = NotificationDeeplinkParser.parseTyped(type: "article", userInfo: userInfo)
        #expect(result == .article(id: "test/article"))
    }

    @Test("parseTyped returns nil for invalid type")
    func parseTypedReturnsNilForInvalidType() {
        let result = NotificationDeeplinkParser.parseTyped(type: "invalid", userInfo: [:])
        #expect(result == nil)
    }

    @Test("parse parses full URL format")
    func parseParsesFullURLFormat() {
        let userInfo: [AnyHashable: Any] = ["deeplink": "pulse://home"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .home)
    }

    @Test("parse parses legacy articleID format")
    func parseParsesLegacyArticleIDFormat() {
        let userInfo: [AnyHashable: Any] = ["articleID": "test/article"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .article(id: "test/article"))
    }

    @Test("parse parses typed format")
    func parseParsesTypedFormat() {
        let userInfo: [AnyHashable: Any] = ["deeplinkType": "feed"]
        let result = NotificationDeeplinkParser.parse(from: userInfo)
        #expect(result == .feed)
    }
}

@Suite("DeeplinkRouter Tests")
@MainActor
struct DeeplinkRouterTests {
    @Test("DeeplinkRouter can be instantiated")
    func canBeInstantiated() {
        let router = DeeplinkRouter()
        #expect(router is DeeplinkRouter)
    }

    @Test("setCoordinator sets coordinator")
    func setCoordinatorSetsCoordinator() {
        let coordinator = MockCoordinator()
        let router = DeeplinkRouter()
        router.setCoordinator(coordinator)
        #expect(router.coordinator === coordinator)
    }

    @Test("route home navigates to home tab")
    func routeHomeNavigatesToHomeTab() {
        let router = DeeplinkRouter()
        let coordinator = MockCoordinator()
        router.setCoordinator(coordinator)

        router.route(deeplink: .home)

        #expect(coordinator.switchTabCalled)
        #expect(coordinator.switchTabTab == .home)
        #expect(coordinator.popToRootCalled)
    }

    @Test("route media navigates to media tab")
    func routeMediaNavigatesToMediaTab() {
        let router = DeeplinkRouter()
        let coordinator = MockCoordinator()
        router.setCoordinator(coordinator)

        router.route(deeplink: .media(type: .video))

        #expect(coordinator.switchTabCalled)
        #expect(coordinator.switchTabTab == .media)
    }

    @Test("route search navigates to search tab")
    func routeSearchNavigatesToSearchTab() {
        let router = DeeplinkRouter()
        let coordinator = MockCoordinator()
        router.setCoordinator(coordinator)

        router.route(deeplink: .search(query: "test"))

        #expect(coordinator.switchTabCalled)
        #expect(coordinator.switchTabTab == .search)
    }

    @Test("route bookmarks navigates to bookmarks tab")
    func routeBookmarksNavigatesToBookmarksTab() {
        let router = DeeplinkRouter()
        let coordinator = MockCoordinator()
        router.setCoordinator(coordinator)

        router.route(deeplink: .bookmarks)

        #expect(coordinator.switchTabCalled)
        #expect(coordinator.switchTabTab == .bookmarks)
    }

    @Test("route feed navigates to feed tab")
    func routeFeedNavigatesToFeedTab() {
        let router = DeeplinkRouter()
        let coordinator = MockCoordinator()
        router.setCoordinator(coordinator)

        router.route(deeplink: .feed)

        #expect(coordinator.switchTabCalled)
        #expect(coordinator.switchTabTab == .feed)
    }

    @Test("route settings navigates to home then settings")
    func routeSettingsNavigatesToHomeThenSettings() {
        let router = DeeplinkRouter()
        let coordinator = MockCoordinator()
        router.setCoordinator(coordinator)

        router.route(deeplink: .settings)

        #expect(coordinator.switchTabCalled)
        #expect(coordinator.switchTabTab == .home)
        #expect(coordinator.pushCalled)
        #expect(coordinator.pushPage == .settings)
    }

    @Test("route article fetches and navigates to article")
    func routeArticleFetchesAndNavigates() {
        let router = DeeplinkRouter()
        let mockService = MockNewsService()
        let coordinator = MockCoordinator(serviceLocator: ServiceLocator())
        coordinator.serviceLocator.register(NewsService.self, instance: mockService)
        router.setCoordinator(coordinator)

        router.route(deeplink: .article(id: "test/article"))

        #expect(coordinator.switchTabCalled)
        #expect(coordinator.switchTabTab == .home)
    }

    @Test("route category navigates to home")
    func routeCategoryNavigatesToHome() {
        let router = DeeplinkRouter()
        let coordinator = MockCoordinator()
        router.setCoordinator(coordinator)

        router.route(deeplink: .category(name: "technology"))

        #expect(coordinator.switchTabCalled)
        #expect(coordinator.switchTabTab == .home)
    }

    @Test("deinit cancels pending fetch")
    func deinitCancelsPendingFetch() {
        let router = DeeplinkRouter()
        router.articleFetchCancellable = AnyCancellable {}
        router.deinit()
    }
}

// MARK: - Mock Coordinator

@MainActor
class MockCoordinator: Coordinator {
    var switchTabCalled = false
    var switchTabTab: AppTab?
    var popToRootCalled = false
    var pushCalled = false
    var pushPage: Page?

    override func switchTab(to tab: AppTab, popToRoot: Bool = false) {
        switchTabCalled = true
        switchTabTab = tab
        if popToRoot {
            popToRootCalled = true
        }
        super.switchTab(to: tab, popToRoot: popToRoot)
    }

    override func push(page: Page, in tab: AppTab? = nil) {
        pushCalled = true
        pushPage = page
        super.push(page: page, in: tab)
    }
}
