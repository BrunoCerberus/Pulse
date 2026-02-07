import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("DeeplinkRouter Tests")
@MainActor
struct DeeplinkRouterTests {
    private var router: DeeplinkRouter!
    private var mockCoordinator: MockCoordinator!

    @Setup
    func setup() {
        mockCoordinator = MockCoordinator()
        router = DeeplinkRouter()
        router.setCoordinator(mockCoordinator)
    }

    @Teardown
    func teardown() {
        router = nil
        mockCoordinator = nil
    }

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

    @Test("parse returns nil for invalid type")
    func parseReturnsNilForInvalidType() {
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

@Suite("DeeplinkManager Tests")
@MainActor
struct DeeplinkManagerTests {
    @Test("shared returns singleton")
    func sharedReturnsSingleton() {
        let manager1 = DeeplinkManager.shared
        let manager2 = DeeplinkManager.shared
        #expect(manager1 === manager2)
    }

    @Test("parseURL parses home deeplink")
    func parseURLParsesHomeDeeplink() throws {
        let manager = DeeplinkManager()
        let url = try #require(URL(string: "pulse://home"))
        manager.parse(url: url)
        #expect(manager.currentDeeplink == .home)
    }

    @Test("parseURL parses media deeplink with type")
    func parseURLParsesMediaDeeplinkWithType() throws {
        let manager = DeeplinkManager()
        let url = try #require(URL(string: "pulse://media?type=video"))
        manager.parse(url: url)
        #expect(manager.currentDeeplink == .media(type: .video))
    }

    @Test("parseURL parses search deeplink with query")
    func parseURLParsesSearchDeeplink() throws {
        let manager = DeeplinkManager()
        let url = try #require(URL(string: "pulse://search?q=swift"))
        manager.parse(url: url)
        #expect(manager.currentDeeplink == .search(query: "swift"))
    }

    @Test("parseURL parses article deeplink")
    func parseURLParsesArticleDeeplink() throws {
        let manager = DeeplinkManager()
        let url = try #require(URL(string: "pulse://article?id=test/article"))
        manager.parse(url: url)
        #expect(manager.currentDeeplink == .article(id: "test/article"))
    }

    @Test("parseURL returns nil for invalid scheme")
    func parseURLReturnsNilForInvalidScheme() throws {
        let manager = DeeplinkManager()
        let url = try #require(URL(string: "https://example.com"))
        manager.parse(url: url)
        #expect(manager.currentDeeplink == nil)
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

@Suite("Coordinator Tests")
@MainActor
struct CoordinatorTests {
    private var serviceLocator: ServiceLocator!
    private var coordinator: Coordinator!

    @Setup
    func setup() {
        serviceLocator = ServiceLocator()
        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(SearchService.self, instance: MockSearchService())
        serviceLocator.register(BookmarksService.self, instance: MockBookmarksService())
        serviceLocator.register(SettingsService.self, instance: MockSettingsService())
        serviceLocator.register(LLMService.self, instance: MockLLMService())
        serviceLocator.register(SummarizationService.self, instance: MockSummarizationService())
        serviceLocator.register(FeedService.self, instance: MockFeedService())
        serviceLocator.register(AuthService.self, instance: MockAuthService())
        serviceLocator.register(StoreKitService.self, instance: MockStoreKitService())

        coordinator = Coordinator(serviceLocator: serviceLocator)
    }

    @Teardown
    func teardown() {
        coordinator = nil
        serviceLocator = nil
    }

    @Test("Coordinator can be instantiated")
    func canBeInstantiated() {
        let coordinator = Coordinator(serviceLocator: serviceLocator)
        #expect(coordinator is Coordinator)
    }

    @Test("initial selectedTab is home")
    func initialSelectedTabIsHome() {
        #expect(coordinator.selectedTab == .home)
    }

    @Test("push adds page to navigation path")
    func pushAddsPageToNavigationPath() throws {
        let article = try #require(Article.mockArticles.first)
        coordinator.push(page: .articleDetail(article))

        #expect(!coordinator.homePath.isEmpty)
    }

    @Test("push adds page to specific tab")
    func pushAddsPageToSpecificTab() throws {
        let article = try #require(Article.mockArticles.first)
        coordinator.push(page: .articleDetail(article), in: .media)

        #expect(!coordinator.mediaPath.isEmpty)
    }

    @Test("pop removes last page from navigation path")
    func popRemovesLastPage() throws {
        let article = try #require(Article.mockArticles.first)
        coordinator.push(page: .articleDetail(article))
        coordinator.pop()

        #expect(coordinator.homePath.isEmpty)
    }

    @Test("popToRoot clears navigation path")
    func popToRootClearsNavigationPath() throws {
        let article = try #require(Article.mockArticles.first)
        coordinator.push(page: .articleDetail(article))
        coordinator.push(page: .articleDetail(article))
        coordinator.popToRoot()

        #expect(coordinator.homePath.isEmpty)
    }

    @Test("switchTab changes selected tab")
    func switchTabChangesSelectedTab() {
        coordinator.switchTab(to: .media)

        #expect(coordinator.selectedTab == .media)
    }

    @Test("switchTab with popToRoot clears navigation path")
    func switchTabWithPopToRootClearsNavigationPath() throws {
        let article = try #require(Article.mockArticles.first)
        coordinator.push(page: .articleDetail(article))
        coordinator.switchTab(to: .media, popToRoot: true)

        #expect(coordinator.homePath.isEmpty)
        #expect(coordinator.selectedTab == .media)
    }

    @Test("build builds article detail view")
    func buildBuildsArticleDetailView() throws {
        let article = try #require(Article.mockArticles.first)
        let view = coordinator.build(page: .articleDetail(article))

        #expect(view is ArticleDetailView)
    }

    @Test("build builds settings view")
    func buildBuildsSettingsView() {
        let view = coordinator.build(page: .settings)

        #expect(view is SettingsView)
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
