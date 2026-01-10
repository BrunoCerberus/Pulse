import Combine
import Foundation

final class MockNewsService: NewsService {
    var topHeadlinesResult: Result<[Article], Error> = .success(Article.mockArticles)
    var breakingNewsResult: Result<[Article], Error> = .success(Array(Article.mockArticles.prefix(3)))

    func fetchTopHeadlines(country _: String, page _: Int) -> AnyPublisher<[Article], Error> {
        topHeadlinesResult.publisher.eraseToAnyPublisher()
    }

    func fetchTopHeadlines(category: NewsCategory, country _: String, page _: Int) -> AnyPublisher<[Article], Error> {
        topHeadlinesResult.publisher
            .map { articles in
                articles.map { article in
                    Article(
                        id: article.id,
                        title: article.title,
                        description: article.description,
                        content: article.content,
                        author: article.author,
                        source: article.source,
                        url: article.url,
                        imageURL: article.imageURL,
                        publishedAt: article.publishedAt,
                        category: category
                    )
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchBreakingNews(country _: String) -> AnyPublisher<[Article], Error> {
        breakingNewsResult.publisher.eraseToAnyPublisher()
    }
}

final class MockSearchService: SearchService {
    var searchResult: Result<[Article], Error> = .success(Article.mockArticles)
    var suggestionsResult: [String] = ["Swift", "iOS", "Apple", "Technology"]

    func search(query _: String, page _: Int, sortBy _: String) -> AnyPublisher<[Article], Error> {
        searchResult.publisher.eraseToAnyPublisher()
    }

    func getSuggestions(for query: String) -> AnyPublisher<[String], Never> {
        Just(suggestionsResult.filter { $0.lowercased().contains(query.lowercased()) })
            .eraseToAnyPublisher()
    }
}

final class MockBookmarksService: BookmarksService {
    var bookmarks: [Article] = []

    func fetchBookmarks() -> AnyPublisher<[Article], Error> {
        Just(bookmarks)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func removeBookmark(_ article: Article) -> AnyPublisher<Void, Error> {
        bookmarks.removeAll { $0.id == article.id }
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

final class MockForYouService: ForYouService {
    var feedResult: Result<[Article], Error> = .success(Article.mockArticles)

    func fetchPersonalizedFeed(preferences _: UserPreferences, page _: Int) -> AnyPublisher<[Article], Error> {
        feedResult.publisher.eraseToAnyPublisher()
    }
}

final class MockSettingsService: SettingsService {
    var preferences: UserPreferences = .default

    func fetchPreferences() -> AnyPublisher<UserPreferences, Error> {
        Just(preferences)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func savePreferences(_ preferences: UserPreferences) -> AnyPublisher<Void, Error> {
        self.preferences = preferences
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func clearReadingHistory() -> AnyPublisher<Void, Error> {
        Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

final class MockStorageService: StorageService {
    var bookmarkedArticles: [Article] = []
    var readingHistory: [Article] = []
    var userPreferences: UserPreferences?

    func saveArticle(_ article: Article) async throws {
        bookmarkedArticles.append(article)
    }

    func deleteArticle(_ article: Article) async throws {
        bookmarkedArticles.removeAll { $0.id == article.id }
    }

    func fetchBookmarkedArticles() async throws -> [Article] {
        bookmarkedArticles
    }

    func isBookmarked(_ articleID: String) async -> Bool {
        bookmarkedArticles.contains { $0.id == articleID }
    }

    func saveReadingHistory(_ article: Article) async throws {
        readingHistory.removeAll { $0.id == article.id }
        readingHistory.insert(article, at: 0)
    }

    func fetchReadingHistory() async throws -> [Article] {
        readingHistory
    }

    func clearReadingHistory() async throws {
        readingHistory.removeAll()
    }

    func saveUserPreferences(_ preferences: UserPreferences) async throws {
        userPreferences = preferences
    }

    func fetchUserPreferences() async throws -> UserPreferences? {
        userPreferences
    }
}

final class MockSummarizationService: SummarizationService {
    private let modelStatusSubject = CurrentValueSubject<LLMModelStatus, Never>(.notLoaded)
    var generateResult: Result<String, Error> = .success(
        "This is a mock AI-generated summary of the article providing key insights and main points."
    )
    var loadDelay: TimeInterval = 0.1
    var generateDelay: TimeInterval = 0.1

    var modelStatusPublisher: AnyPublisher<LLMModelStatus, Never> {
        modelStatusSubject.eraseToAnyPublisher()
    }

    var isModelLoaded: Bool {
        if case .ready = modelStatusSubject.value { return true }
        return false
    }

    func loadModelIfNeeded() async throws {
        guard !isModelLoaded else { return }
        modelStatusSubject.send(.loading(progress: 0.5))
        try await Task.sleep(nanoseconds: UInt64(loadDelay * 1_000_000_000))
        modelStatusSubject.send(.ready)
    }

    func summarize(article _: Article) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [self] continuation in
            Task {
                let delayPerWord = UInt64(generateDelay * 1_000_000_000 / 4)

                switch generateResult {
                case let .success(text):
                    for word in text.split(separator: " ") {
                        try? await Task.sleep(nanoseconds: delayPerWord)
                        continuation.yield(String(word) + " ")
                    }
                    continuation.finish()
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func cancelSummarization() {}
}

final class MockLLMService: LLMService {
    var modelStatus: LLMModelStatus = .notLoaded
    var generateResult: Result<String, Error> = .success(
        "Mock AI digest content with enough words to trigger progress updates during generation."
    )
    var loadDelay: TimeInterval = 0.1
    var generateDelay: TimeInterval = 0.1
    var shouldSimulateMemoryPressure = false

    private let modelStatusSubject = CurrentValueSubject<LLMModelStatus, Never>(.notLoaded)

    var modelStatusPublisher: AnyPublisher<LLMModelStatus, Never> {
        modelStatusSubject.eraseToAnyPublisher()
    }

    var isModelLoaded: Bool {
        if case .ready = modelStatusSubject.value { return true }
        return false
    }

    func loadModel() async throws {
        modelStatusSubject.send(.loading(progress: 0.5))
        try await Task.sleep(nanoseconds: UInt64(loadDelay * 1_000_000_000))

        if shouldSimulateMemoryPressure {
            modelStatusSubject.send(.error("Memory pressure"))
            throw LLMError.memoryPressure
        }

        modelStatusSubject.send(.ready)
    }

    func unloadModel() async {
        modelStatusSubject.send(.notLoaded)
    }

    func generate(
        prompt _: String,
        systemPrompt _: String?,
        config _: LLMInferenceConfig
    ) -> AnyPublisher<String, Error> {
        Just(())
            .delay(for: .seconds(generateDelay), scheduler: DispatchQueue.main)
            .flatMap { [self] _ in
                generateResult.publisher
            }
            .eraseToAnyPublisher()
    }

    func generateStream(
        prompt _: String,
        systemPrompt _: String?,
        config _: LLMInferenceConfig
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [self] continuation in
            Task {
                // Use generateDelay per word for longer running stream
                let delayPerWord = UInt64(generateDelay * 1_000_000_000 / 4)

                switch generateResult {
                case let .success(text):
                    for word in text.split(separator: " ") {
                        try? await Task.sleep(nanoseconds: delayPerWord)
                        continuation.yield(String(word) + " ")
                    }
                    continuation.finish()
                case let .failure(error):
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func cancelGeneration() {}
}

final class MockRemoteConfigService: RemoteConfigService {
    var guardianAPIKeyValue: String?
    var newsAPIKeyValue: String?
    var gnewsAPIKeyValue: String?
    var shouldThrowOnFetch = false

    func fetchAndActivate() async throws {
        if shouldThrowOnFetch {
            throw RemoteConfigError.fetchFailed
        }
    }

    func getStringOrNil(forKey key: RemoteConfigKey) -> String? {
        switch key {
        case .guardianAPIKey: guardianAPIKeyValue
        case .newsAPIKey: newsAPIKeyValue
        case .gnewsAPIKey: gnewsAPIKeyValue
        }
    }

    var guardianAPIKey: String? { guardianAPIKeyValue }
    var newsAPIKey: String? { newsAPIKeyValue }
    var gnewsAPIKey: String? { gnewsAPIKeyValue }
}

extension ServiceLocator {
    static var preview: ServiceLocator {
        let locator = ServiceLocator()
        locator.register(NewsService.self, instance: MockNewsService())
        locator.register(SearchService.self, instance: MockSearchService())
        locator.register(BookmarksService.self, instance: MockBookmarksService())
        locator.register(ForYouService.self, instance: MockForYouService())
        locator.register(SettingsService.self, instance: MockSettingsService())
        locator.register(StorageService.self, instance: MockStorageService())
        locator.register(StoreKitService.self, instance: MockStoreKitService())
        locator.register(RemoteConfigService.self, instance: MockRemoteConfigService())
        locator.register(LLMService.self, instance: MockLLMService())
        locator.register(SummarizationService.self, instance: MockSummarizationService())

        // Auth service with mock signed-in user
        let mockAuth = MockAuthService()
        mockAuth.simulateSignedIn(.mock)
        locator.register(AuthService.self, instance: mockAuth)

        return locator
    }

    static var previewUnauthenticated: ServiceLocator {
        let locator = ServiceLocator()
        locator.register(NewsService.self, instance: MockNewsService())
        locator.register(SearchService.self, instance: MockSearchService())
        locator.register(BookmarksService.self, instance: MockBookmarksService())
        locator.register(ForYouService.self, instance: MockForYouService())
        locator.register(SettingsService.self, instance: MockSettingsService())
        locator.register(StorageService.self, instance: MockStorageService())
        locator.register(StoreKitService.self, instance: MockStoreKitService())
        locator.register(RemoteConfigService.self, instance: MockRemoteConfigService())
        locator.register(LLMService.self, instance: MockLLMService())
        locator.register(SummarizationService.self, instance: MockSummarizationService())
        locator.register(AuthService.self, instance: MockAuthService())
        return locator
    }
}

extension Article {
    static var mockArticles: [Article] {
        [
            Article(
                id: "1",
                title: "SwiftUI 6.0 Brings Revolutionary New Features",
                description: "Apple announces major updates to SwiftUI at WWDC 2024",
                content: "Full article content here...",
                author: "John Appleseed",
                source: ArticleSource(id: "techcrunch", name: "TechCrunch"),
                url: "https://example.com/1",
                imageURL: "https://picsum.photos/400/300",
                publishedAt: Date(),
                category: .technology
            ),
            Article(
                id: "2",
                title: "Global Markets Rally on Economic Data",
                description: "Stock markets see gains across major indices",
                content: "Full article content here...",
                author: "Jane Doe",
                source: ArticleSource(id: "reuters", name: "Reuters"),
                url: "https://example.com/2",
                imageURL: "https://picsum.photos/400/301",
                publishedAt: Date().addingTimeInterval(-3600),
                category: .business
            ),
            Article(
                id: "3",
                title: "New Study Reveals Health Benefits of Exercise",
                description: "Research shows positive effects on mental health",
                content: "Full article content here...",
                author: "Dr. Smith",
                source: ArticleSource(id: "bbc", name: "BBC Health"),
                url: "https://example.com/3",
                imageURL: "https://picsum.photos/400/302",
                publishedAt: Date().addingTimeInterval(-7200),
                category: .health
            ),
            Article(
                id: "4",
                title: "Championship Finals Set New Viewership Records",
                description: "Historic game draws millions of viewers worldwide",
                content: "Full article content here...",
                author: "Sports Desk",
                source: ArticleSource(id: "espn", name: "ESPN"),
                url: "https://example.com/4",
                imageURL: "https://picsum.photos/400/303",
                publishedAt: Date().addingTimeInterval(-10800),
                category: .sports
            ),
            Article(
                id: "5",
                title: "Breakthrough in Quantum Computing Research",
                description: "Scientists achieve new milestone in quantum processing",
                content: "Full article content here...",
                author: "Dr. Quantum",
                source: ArticleSource(id: "nature", name: "Nature"),
                url: "https://example.com/5",
                imageURL: "https://picsum.photos/400/304",
                publishedAt: Date().addingTimeInterval(-14400),
                category: .science
            ),
        ]
    }
}
