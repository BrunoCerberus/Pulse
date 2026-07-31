import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

// MARK: - Full Article Body Fetch Tests

/// Covers the by-id body fetch: list responses omit `content`, so the row the
/// detail screen is opened with carries only the source's short summary and
/// the body has to be pulled separately.
@Suite("ArticleDetailDomainInteractor Full Article Fetch Tests")
@MainActor
struct ArticleDetailFullArticleFetchTests {
    private let mockNewsService: MockNewsService
    private let serviceLocator: ServiceLocator

    /// Stands in for the row handed over by a list: summary only, no body.
    private static let summaryOnly = Article(
        id: "article-1",
        title: "Headline",
        description: nil,
        content: "Short summary from the feed.",
        source: ArticleSource(id: nil, name: "Test Source"),
        url: "https://example.com",
        publishedAt: Date(),
        category: .world,
    )

    /// What the detail endpoint returns for the same id.
    private static let withBody = Article(
        id: "article-1",
        title: "Headline",
        description: "Short summary from the feed.",
        content: "First body sentence. Second body sentence. Third body sentence.",
        source: ArticleSource(id: nil, name: "Test Source"),
        url: "https://example.com",
        publishedAt: Date(),
        category: .world,
    )

    init() {
        mockNewsService = MockNewsService()
        serviceLocator = ServiceLocator()
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
        serviceLocator.register(NewsService.self, instance: mockNewsService)
    }

    private func createSUT(article: Article = summaryOnly) -> ArticleDetailDomainInteractor {
        ArticleDetailDomainInteractor(article: article, serviceLocator: serviceLocator)
    }

    @Test("onAppear swaps in the fetched body and reprocesses content")
    func onAppearSwapsInFullBody() async {
        mockNewsService.fetchArticleResult = .success(Self.withBody)
        let sut = createSUT()

        sut.dispatch(action: .onAppear)

        let swapped = await waitForCondition(timeout: TestWaitDuration.long) { @MainActor in
            sut.currentState.article.content == Self.withBody.content
        }
        #expect(swapped)

        let reprocessed = await waitForCondition(timeout: TestWaitDuration.long) { @MainActor in
            !sut.currentState.isProcessingContent && sut.currentState.processedContent != nil
        }
        #expect(reprocessed)
        // The body arrived, so the summary is now available as the lede.
        #expect(sut.currentState.processedDescription != nil)
    }

    @Test("Fetch failure leaves the summary on screen")
    func fetchFailureKeepsSummary() async {
        mockNewsService.fetchArticleResult = .failure(URLError(.resourceUnavailable))
        let sut = createSUT()

        sut.dispatch(action: .onAppear)
        try? await Task.sleep(nanoseconds: TestWaitDuration.long)

        #expect(sut.currentState.article.content == Self.summaryOnly.content)
        #expect(sut.currentState.processedContent != nil)
        #expect(!sut.currentState.isProcessingContent)
    }

    @Test("A body identical to the summary does not trigger a swap")
    func identicalBodyDoesNotSwap() async {
        // What the endpoint returns for an article whose body was pruned
        // server-side: `content` falls back to the summary, same as the list row.
        mockNewsService.fetchArticleResult = .success(Self.summaryOnly)
        let sut = createSUT()

        sut.dispatch(action: .onAppear)
        try? await Task.sleep(nanoseconds: TestWaitDuration.long)

        #expect(sut.currentState.article == Self.summaryOnly)
        #expect(!sut.currentState.isProcessingContent)
    }

    @Test("onAppear firing twice fetches the body only once")
    func repeatedOnAppearFetchesOnce() async {
        mockNewsService.fetchArticleResult = .success(Self.withBody)
        let sut = createSUT()

        sut.dispatch(action: .onAppear)
        sut.dispatch(action: .onAppear)
        try? await Task.sleep(nanoseconds: TestWaitDuration.long)

        #expect(mockNewsService.fetchedArticleIDs == ["article-1"])
    }

    @Test("The body is requested by the article's own id")
    func fetchesByArticleID() async {
        mockNewsService.fetchArticleResult = .success(Self.withBody)
        let sut = createSUT()

        sut.dispatch(action: .onAppear)
        try? await Task.sleep(nanoseconds: TestWaitDuration.long)

        #expect(mockNewsService.fetchedArticleIDs.first == Self.summaryOnly.id)
    }

    @Test("Reprocessing the swapped-in body reports work in flight")
    func reprocessingFlagsProcessing() async {
        let sut = createSUT()

        // The flag starts `true` from `initial(article:)`, so the first pass has
        // to finish before this asserts anything — otherwise it passes whether
        // or not the handler raises it again.
        let firstPassDone = await waitForCondition(timeout: TestWaitDuration.long) { @MainActor in
            !sut.currentState.isProcessingContent
        }
        #expect(firstPassDone)

        // Drive the handler directly: the flag is raised synchronously with the
        // state swap, before the detached processing task can clear it.
        sut.dispatch(action: .fullArticleLoaded(Self.withBody))

        #expect(sut.currentState.isProcessingContent)
        #expect(sut.currentState.article.content == Self.withBody.content)
    }
}
