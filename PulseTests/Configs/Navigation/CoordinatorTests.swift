import EntropyCore
import Foundation
@testable import Pulse
import SwiftUI
import Testing

@Suite("Coordinator Tests")
@MainActor
struct CoordinatorTests {
    let serviceLocator: ServiceLocator
    let sut: Coordinator

    init() {
        serviceLocator = ServiceLocator()
        // Register mock services
        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(SearchService.self, instance: MockSearchService())
        serviceLocator.register(ForYouService.self, instance: MockForYouService())
        serviceLocator.register(LLMService.self, instance: MockLLMService())
        serviceLocator.register(SummarizationService.self, instance: MockSummarizationService())
        serviceLocator.register(BookmarksService.self, instance: MockBookmarksService())
        serviceLocator.register(SettingsService.self, instance: MockSettingsService())

        sut = Coordinator(serviceLocator: serviceLocator)
    }

    // MARK: - Initial State Tests (Consolidated)

    @Test("Initial state has home tab selected and all paths empty")
    func initialStateIsCorrect() {
        #expect(sut.selectedTab == .home)
        #expect(sut.homePath.isEmpty)
        #expect(sut.forYouPath.isEmpty)
        #expect(sut.bookmarksPath.isEmpty)
        #expect(sut.searchPath.isEmpty)
    }

    // MARK: - Push Tests

    @Test("Push adds page to current tab path")
    func pushAddsPageToCurrentTabPath() {
        sut.selectedTab = .home
        let article = Article.mockArticles[0]

        sut.push(page: .articleDetail(article))

        #expect(sut.homePath.count == 1)
    }

    @Test("Push to specific tab adds page to that tab")
    func pushToSpecificTabAddsPageToThatTab() {
        sut.selectedTab = .home
        let article = Article.mockArticles[0]

        sut.push(page: .articleDetail(article), in: .forYou)

        #expect(sut.forYouPath.count == 1)
        #expect(sut.homePath.isEmpty)
    }

    @Test("Push settings to home tab")
    func pushSettingsToHomeTab() {
        sut.selectedTab = .home

        sut.push(page: .settings)

        #expect(sut.homePath.count == 1)
    }

    @Test("Multiple pushes stack pages")
    func multiplePushesStackPages() {
        sut.selectedTab = .home
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]

        sut.push(page: .articleDetail(article1))
        sut.push(page: .articleDetail(article2))

        #expect(sut.homePath.count == 2)
    }

    // MARK: - Pop Tests

    @Test("Pop removes last page from current tab")
    func popRemovesLastPageFromCurrentTab() {
        sut.selectedTab = .home
        let article = Article.mockArticles[0]
        sut.push(page: .articleDetail(article))
        #expect(sut.homePath.count == 1)

        sut.pop()

        #expect(sut.homePath.isEmpty)
    }

    @Test("Pop on empty path does nothing")
    func popOnEmptyPathDoesNothing() {
        sut.selectedTab = .home
        #expect(sut.homePath.isEmpty)

        sut.pop()

        #expect(sut.homePath.isEmpty)
    }

    @Test("Pop removes only last page")
    func popRemovesOnlyLastPage() {
        sut.selectedTab = .home
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        sut.push(page: .articleDetail(article1))
        sut.push(page: .articleDetail(article2))
        #expect(sut.homePath.count == 2)

        sut.pop()

        #expect(sut.homePath.count == 1)
    }

    // MARK: - Pop To Root Tests

    @Test("Pop to root clears current tab path")
    func popToRootClearsCurrentTabPath() {
        sut.selectedTab = .home
        let article1 = Article.mockArticles[0]
        let article2 = Article.mockArticles[1]
        sut.push(page: .articleDetail(article1))
        sut.push(page: .articleDetail(article2))

        sut.popToRoot()

        #expect(sut.homePath.isEmpty)
    }

    @Test("Pop to root in specific tab clears that tab")
    func popToRootInSpecificTabClearsThatTab() {
        sut.selectedTab = .home
        let article = Article.mockArticles[0]
        sut.push(page: .articleDetail(article), in: .forYou)

        sut.popToRoot(in: .forYou)

        #expect(sut.forYouPath.isEmpty)
    }

    @Test("Pop to root does not affect other tabs")
    func popToRootDoesNotAffectOtherTabs() {
        let article = Article.mockArticles[0]
        sut.push(page: .articleDetail(article), in: .home)
        sut.push(page: .articleDetail(article), in: .forYou)

        sut.popToRoot(in: .home)

        #expect(sut.homePath.isEmpty)
        #expect(sut.forYouPath.count == 1)
    }

    // MARK: - Switch Tab Tests

    @Test("Switch tab changes selected tab")
    func switchTabChangesSelectedTab() {
        sut.selectedTab = .home

        sut.switchTab(to: .search)

        #expect(sut.selectedTab == .search)
    }

    @Test("Switch tab with popToRoot clears target tab")
    func switchTabWithPopToRootClearsTargetTab() {
        let article = Article.mockArticles[0]
        sut.push(page: .articleDetail(article), in: .forYou)

        sut.switchTab(to: .forYou, popToRoot: true)

        #expect(sut.selectedTab == .forYou)
        #expect(sut.forYouPath.isEmpty)
    }

    @Test("Switch tab without popToRoot preserves navigation")
    func switchTabWithoutPopToRootPreservesNavigation() {
        let article = Article.mockArticles[0]
        sut.push(page: .articleDetail(article), in: .forYou)

        sut.switchTab(to: .forYou, popToRoot: false)

        #expect(sut.selectedTab == .forYou)
        #expect(sut.forYouPath.count == 1)
    }

    // MARK: - Tab Independence Tests

    @Test("Each tab maintains independent navigation")
    func eachTabMaintainsIndependentNavigation() {
        let article = Article.mockArticles[0]

        sut.push(page: .articleDetail(article), in: .home)
        sut.push(page: .settings, in: .home)
        sut.push(page: .articleDetail(article), in: .forYou)
        sut.push(page: .articleDetail(article), in: .bookmarks)

        #expect(sut.homePath.count == 2)
        #expect(sut.forYouPath.count == 1)
        #expect(sut.bookmarksPath.count == 1)
        #expect(sut.searchPath.isEmpty)
    }

    @Test("Switching tabs preserves all navigation state")
    func switchingTabsPreservesAllNavigationState() {
        let article = Article.mockArticles[0]
        sut.push(page: .articleDetail(article), in: .home)
        sut.push(page: .articleDetail(article), in: .forYou)

        sut.switchTab(to: .search)
        sut.switchTab(to: .bookmarks)
        sut.switchTab(to: .home)

        #expect(sut.homePath.count == 1)
        #expect(sut.forYouPath.count == 1)
    }

    // MARK: - ViewModel Lazy Initialization Tests (Consolidated)

    @Test("All ViewModels are lazily initialized and non-nil after access")
    func allViewModelsAreLazilyInitialized() {
        // Access each viewModel and verify it's not nil
        #expect(sut.homeViewModel != nil)
        #expect(sut.forYouViewModel != nil)
        #expect(sut.bookmarksViewModel != nil)
        #expect(sut.searchViewModel != nil)
        #expect(sut.settingsViewModel != nil)
    }

    // MARK: - AppTab Tests

    @Test("AppTab has all expected cases with symbol images")
    func appTabHasAllExpectedCasesWithSymbols() {
        let allTabs = AppTab.allCases
        #expect(allTabs.count == 4)
        #expect(allTabs.contains(.home))
        #expect(allTabs.contains(.forYou))
        #expect(allTabs.contains(.bookmarks))
        #expect(allTabs.contains(.search))

        for tab in AppTab.allCases {
            #expect(!tab.symbolImage.isEmpty)
        }
    }
}
