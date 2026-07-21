import Combine
import EntropyCore
@testable import Pulse
import SwiftUI
import Testing
import UIKit

@Suite("Patch coverage rendering tests")
@MainActor
struct PatchCoverageRenderingTests {
    @Test("Hero news card renders glass overlay")
    func heroNewsCardRendersGlassOverlay() {
        Self.render(
            HeroNewsCard(
                item: ArticleViewItem(from: Self.article),
                onTap: {},
            )
            .frame(width: 320, height: 240),
        )
    }

    @Test("Featured media card renders glass overlay")
    func featuredMediaCardRendersGlassOverlay() {
        Self.render(
            FeaturedMediaCard(
                item: MediaViewItem(from: Self.article),
                onTap: {},
            )
            .frame(width: 320, height: 220),
        )
    }

    @Test("Featured media skeleton renders glass overlay")
    func featuredMediaSkeletonRendersGlassOverlay() {
        Self.render(
            FeaturedMediaCardSkeleton()
                .frame(width: 320, height: 220),
        )
    }

    @Test("Search sorting state renders glass progress overlay")
    func searchSortingStateRendersGlassProgressOverlay() async {
        let searchService = ControlledSearchService()
        let serviceLocator = ServiceLocator()
        serviceLocator.register(SearchService.self, instance: searchService)
        serviceLocator.register(StorageService.self, instance: MockStorageService())

        let viewModel = SearchViewModel(serviceLocator: serviceLocator)
        viewModel.handle(event: .onQueryChanged("swift"))
        viewModel.handle(event: .onSearch)
        try? await Task.sleep(nanoseconds: TestWaitDuration.short)

        let didLoadResults = viewModel.viewState.hasSearched
            && !viewModel.viewState.results.isEmpty
            && !viewModel.viewState.isLoading
        #expect(didLoadResults)

        searchService.delayNextSearch = true
        viewModel.handle(event: .onSortChanged(.publishedAt))
        var didEnterSortingState = false
        for _ in 0 ..< 50 where !didEnterSortingState {
            didEnterSortingState = viewModel.viewState.isSorting
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        #expect(didEnterSortingState)
        Self.render(
            NavigationStack {
                SearchView(router: SearchNavigationRouter(), viewModel: viewModel)
            },
            size: CGSize(width: 393, height: 852),
        )
        searchService.completeDelayedSearch()
    }

    private static func render(
        _ view: some View,
        size: CGSize = CGSize(width: 393, height: 260),
    ) {
        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            Issue.record("Expected an active window scene for rendering")
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.frame = CGRect(origin: .zero, size: size)
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: size)

        window.rootViewController = controller
        window.makeKeyAndVisible()
        window.setNeedsLayout()
        window.layoutIfNeeded()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        withExtendedLifetime(window) {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
    }

    private static var article: Article {
        Article(
            id: "patch-coverage-article",
            title: "Liquid Glass coverage article",
            description: "A stable article for rendering changed glass overlays.",
            source: ArticleSource(id: "pulse", name: "Pulse"),
            url: "https://example.com/patch-coverage",
            imageURL: nil,
            publishedAt: Date(timeIntervalSince1970: 1_700_000_000),
            category: .technology,
            mediaType: .video,
            mediaDuration: 180,
        )
    }
}

private final class ControlledSearchService: SearchService {
    var delayNextSearch = false

    private var delayedSearch: PassthroughSubject<[Article], Error>?
    private let results = Array(Article.mockArticles.prefix(3))

    func search(query _: String, page _: Int, sortBy _: String) -> AnyPublisher<[Article], Error> {
        if delayNextSearch {
            let subject = PassthroughSubject<[Article], Error>()
            delayedSearch = subject
            delayNextSearch = false
            return subject.eraseToAnyPublisher()
        }

        return Just(results)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func getSuggestions(for _: String) -> AnyPublisher<[String], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func clearRecentSearches() {}

    func completeDelayedSearch() {
        delayedSearch?.send(results)
        delayedSearch?.send(completion: .finished)
    }
}
