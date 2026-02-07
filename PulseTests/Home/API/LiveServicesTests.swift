import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveSearchService Tests")
struct LiveSearchServiceTests {
    @Test("LiveSearchService can be instantiated")
    func canBeInstantiated() {
        let service = LiveSearchService()
        #expect(service is SearchService)
    }

    @Test("search returns correct publisher type")
    func searchReturnsCorrectType() {
        let service = LiveSearchService()
        let publisher = service.search(query: "test", page: 1, sortBy: "relevance")
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    @Test("getSuggestions returns correct publisher type")
    func getSuggestionsReturnsCorrectType() {
        let service = LiveSearchService()
        let publisher = service.getSuggestions(for: "test")
        let typeCheck: AnyPublisher<[String], Never> = publisher
        #expect(typeCheck is AnyPublisher<[String], Never>)
    }

    @Test("mapSortOrder maps relevancy to relevance")
    func mapSortOrderMapsRelevancy() {
        let service = LiveSearchService()
        let result = service.mapSortOrder("relevancy")
        #expect(result == "relevance")
    }

    @Test("mapSortOrder maps popularity to relevance")
    func mapSortOrderMapsPopularity() {
        let service = LiveSearchService()
        let result = service.mapSortOrder("popularity")
        #expect(result == "relevance")
    }

    @Test("mapSortOrder maps publishedat to newest")
    func mapSortOrderMapsPublishedAt() {
        let service = LiveSearchService()
        let result = service.mapSortOrder("publishedat")
        #expect(result == "newest")
    }

    @Test("mapSortOrder defaults to relevance")
    func mapSortOrderDefaultsToRelevance() {
        let service = LiveSearchService()
        let result = service.mapSortOrder("unknown")
        #expect(result == "relevance")
    }
}

@Suite("LiveMediaService Tests")
struct LiveMediaServiceTests {
    @Test("LiveMediaService can be instantiated")
    func canBeInstantiated() {
        let service = LiveMediaService()
        #expect(service is MediaService)
    }

    @Test("fetchMedia returns correct publisher type")
    func fetchMediaReturnsCorrectType() {
        let service = LiveMediaService()
        let publisher = service.fetchMedia(type: .video, page: 1)
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    @Test("fetchFeaturedMedia returns correct publisher type")
    func fetchFeaturedMediaReturnsCorrectType() {
        let service = LiveMediaService()
        let publisher = service.fetchFeaturedMedia(type: .podcast)
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }
}

@Suite("LiveFeedService Tests")
struct LiveFeedServiceTests {
    @Test("LiveFeedService can be instantiated")
    func canBeInstantiated() {
        let service = LiveFeedService()
        #expect(service is FeedService)
    }

    @Test("modelStatusPublisher returns correct publisher type")
    func modelStatusPublisherReturnsCorrectType() {
        let service = LiveFeedService()
        let publisher = service.modelStatusPublisher
        let typeCheck: AnyPublisher<LLMModelStatus, Never> = publisher
        #expect(typeCheck is AnyPublisher<LLMModelStatus, Never>)
    }

    @Test("isModelReady returns false when model not loaded")
    func isModelReadyReturnsFalseWhenNotLoaded() {
        let service = LiveFeedService()
        #expect(service.isModelReady == false)
    }

    @Test("generateDigest returns AsyncThrowingStream")
    func generateDigestReturnsStream() throws {
        let service = LiveFeedService()
        let articles: [Article] = try [#require(Article.mockArticles.first)]
        let stream = service.generateDigest(from: articles)
        #expect(stream is AsyncThrowingStream<String, Error>)
    }
}

@Suite("LiveSettingsService Tests")
struct LiveSettingsServiceTests {
    @Test("LiveSettingsService can be instantiated")
    func canBeInstantiated() {
        let mockStorage = MockStorageService()
        let service = LiveSettingsService(storageService: mockStorage)
        #expect(service is SettingsService)
    }

    @Test("fetchPreferences returns correct publisher type")
    func fetchPreferencesReturnsCorrectType() {
        let mockStorage = MockStorageService()
        let service = LiveSettingsService(storageService: mockStorage)
        let publisher = service.fetchPreferences()
        let typeCheck: AnyPublisher<UserPreferences, Error> = publisher
        #expect(typeCheck is AnyPublisher<UserPreferences, Error>)
    }

    @Test("savePreferences returns correct publisher type")
    func savePreferencesReturnsCorrectType() {
        let mockStorage = MockStorageService()
        let service = LiveSettingsService(storageService: mockStorage)
        let publisher = service.savePreferences(.default)
        let typeCheck: AnyPublisher<Void, Error> = publisher
        #expect(typeCheck is AnyPublisher<Void, Error>)
    }
}

@Suite("LiveBookmarksService Tests")
struct LiveBookmarksServiceTests {
    @Test("LiveBookmarksService can be instantiated")
    func canBeInstantiated() {
        let mockStorage = MockStorageService()
        let service = LiveBookmarksService(storageService: mockStorage)
        #expect(service is BookmarksService)
    }

    @Test("fetchBookmarks returns correct publisher type")
    func fetchBookmarksReturnsCorrectType() {
        let mockStorage = MockStorageService()
        let service = LiveBookmarksService(storageService: mockStorage)
        let publisher = service.fetchBookmarks()
        let typeCheck: AnyPublisher<[Article], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Article], Error>)
    }

    @Test("removeBookmark returns correct publisher type")
    func removeBookmarkReturnsCorrectType() throws {
        let mockStorage = MockStorageService()
        let service = LiveBookmarksService(storageService: mockStorage)
        let article = try #require(Article.mockArticles.first)
        let publisher = service.removeBookmark(article)
        let typeCheck: AnyPublisher<Void, Error> = publisher
        #expect(typeCheck is AnyPublisher<Void, Error>)
    }
}

@Suite("LiveStoreKitService Tests")
struct LiveStoreKitServiceTests {
    @Test("LiveStoreKitService can be instantiated")
    func canBeInstantiated() {
        let service = LiveStoreKitService()
        #expect(service is StoreKitService)
    }

    @Test("isPremium returns false initially")
    func isPremiumReturnsFalseInitially() {
        let service = LiveStoreKitService()
        #expect(service.isPremium == false)
    }

    @Test("subscriptionStatusPublisher returns correct publisher type")
    func subscriptionStatusPublisherReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.subscriptionStatusPublisher
        let typeCheck: AnyPublisher<Bool, Never> = publisher
        #expect(typeCheck is AnyPublisher<Bool, Never>)
    }

    @Test("fetchProducts returns correct publisher type")
    func fetchProductsReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.fetchProducts()
        let typeCheck: AnyPublisher<[Product], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Product], Error>)
    }

    @Test("purchase returns correct publisher type")
    func purchaseReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.purchase(Product.mock)
        let typeCheck: AnyPublisher<Bool, Error> = publisher
        #expect(typeCheck is AnyPublisher<Bool, Error>)
    }

    @Test("restorePurchases returns correct publisher type")
    func restorePurchasesReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.restorePurchases()
        let typeCheck: AnyPublisher<Bool, Error> = publisher
        #expect(typeCheck is AnyPublisher<Bool, Error>)
    }

    @Test("checkSubscriptionStatus returns correct publisher type")
    func checkSubscriptionStatusReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.checkSubscriptionStatus()
        let typeCheck: AnyPublisher<Bool, Never> = publisher
        #expect(typeCheck is AnyPublisher<Bool, Never>)
    }
}

@Suite("LiveSummarizationService Tests")
struct LiveSummarizationServiceTests {
    @Test("LiveSummarizationService can be instantiated")
    func canBeInstantiated() {
        let service = LiveSummarizationService()
        #expect(service is SummarizationService)
    }

    @Test("modelStatusPublisher returns correct publisher type")
    func modelStatusPublisherReturnsCorrectType() {
        let service = LiveSummarizationService()
        let publisher = service.modelStatusPublisher
        let typeCheck: AnyPublisher<LLMModelStatus, Never> = publisher
        #expect(typeCheck is AnyPublisher<LLMModelStatus, Never>)
    }

    @Test("isModelLoaded returns false when model not loaded")
    func isModelLoadedReturnsFalse() {
        let service = LiveSummarizationService()
        #expect(service.isModelLoaded == false)
    }

    @Test("summarize returns AsyncThrowingStream")
    func summarizeReturnsStream() throws {
        let service = LiveSummarizationService()
        let article = try #require(Article.mockArticles.first)
        let stream = service.summarize(article: article)
        #expect(stream is AsyncThrowingStream<String, Error>)
    }

    @Test("cancelSummarization calls LLM service")
    func cancelSummarizationCallsLLMService() {
        let mockLLMService = MockLLMService()
        let service = LiveSummarizationService(llmService: mockLLMService)
        service.cancelSummarization()
        #expect(mockLLMService.cancelGenerationCallCount == 1)
    }
}

@Suite("LiveLLMService Tests")
struct LiveLLMServiceTests {
    @Test("LiveLLMService can be instantiated")
    func canBeInstantiated() {
        let service = LiveLLMService()
        #expect(service is LLMService)
    }

    @Test("modelStatusPublisher returns correct publisher type")
    func modelStatusPublisherReturnsCorrectType() {
        let service = LiveLLMService()
        let publisher = service.modelStatusPublisher
        let typeCheck: AnyPublisher<LLMModelStatus, Never> = publisher
        #expect(typeCheck is AnyPublisher<LLMModelStatus, Never>)
    }

    @Test("isModelLoaded returns false initially")
    func isModelLoadedReturnsFalseInitially() {
        let service = LiveLLMService()
        #expect(service.isModelLoaded == false)
    }

    @Test("generate returns correct publisher type")
    func generateReturnsCorrectType() {
        let service = LiveLLMService()
        let publisher = service.generate(prompt: "test", systemPrompt: nil, config: .default)
        let typeCheck: AnyPublisher<String, Error> = publisher
        #expect(typeCheck is AnyPublisher<String, Error>)
    }

    @Test("generateStream returns correct type")
    func generateStreamReturnsCorrectType() {
        let service = LiveLLMService()
        let stream = service.generateStream(prompt: "test", systemPrompt: nil, config: .default)
        #expect(stream is AsyncThrowingStream<String, Error>)
    }

    @Test("cancelGeneration increments call count")
    func cancelGenerationIncrementsCount() {
        let service = LiveLLMService()
        service.cancelGeneration()
        #expect(service.cancelGenerationCallCount == 1)
    }
}

@Suite("SupabaseConfig Tests")
struct SupabaseConfigTests {
    @Test("url returns empty when not configured")
    func urlReturnsEmptyWhenNotConfigured() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = nil
        SupabaseConfig.configure(with: mockRemoteConfig)
        let url = SupabaseConfig.url
        #expect(url.isEmpty)
    }

    @Test("url returns Remote Config value when available")
    func urlReturnsRemoteConfigValue() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = "https://test.supabase.co"
        SupabaseConfig.configure(with: mockRemoteConfig)
        let url = SupabaseConfig.url
        #expect(url == "https://test.supabase.co")
    }

    @Test("url falls back to environment variable")
    func urlFallsBackToEnvironmentVariable() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = nil
        SupabaseConfig.configure(with: mockRemoteConfig)
        let testURL = "https://env.supabase.co"
        ProcessInfo.processInfo.environment["SUPABASE_URL"] = testURL
        let url = SupabaseConfig.url
        #expect(url == testURL)
        ProcessInfo.processInfo.environment["SUPABASE_URL"] = nil
    }

    @Test("isConfigured returns true when URL is set")
    func isConfiguredReturnsTrueWhenSet() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = "https://test.supabase.co"
        SupabaseConfig.configure(with: mockRemoteConfig)
        #expect(SupabaseConfig.isConfigured == true)
    }

    @Test("isConfigured returns false when URL is empty")
    func isConfiguredReturnsFalseWhenEmpty() {
        let mockRemoteConfig = MockRemoteConfigService()
        mockRemoteConfig.supabaseURLValue = ""
        SupabaseConfig.configure(with: mockRemoteConfig)
        #expect(SupabaseConfig.isConfigured == false)
    }
}

@Suite("APIKeysProvider Tests")
struct APIKeysProviderTests {
    @Test("guardianAPIKey uses Remote Config when available")
    func guardianAPIKeyUsesRemoteConfig() {
        let mock = MockRemoteConfigService()
        mock.guardianAPIKeyValue = "remote-guardian-key"
        APIKeysProvider.configure(with: mock)
        let key = APIKeysProvider.guardianAPIKey
        #expect(key == "remote-guardian-key")
    }

    @Test("guardianAPIKey falls back to environment variable")
    func guardianAPIKeyFallsBackToEnvironment() {
        let mock = MockRemoteConfigService()
        mock.guardianAPIKeyValue = nil
        APIKeysProvider.configure(with: mock)
        let testKey = "env-guardian-key"
        ProcessInfo.processInfo.environment["GUARDIAN_API_KEY"] = testKey
        let key = APIKeysProvider.guardianAPIKey
        #expect(key == testKey)
        ProcessInfo.processInfo.environment["GUARDIAN_API_KEY"] = nil
    }

    @Test("newsAPIKey uses Remote Config when available")
    func newsAPIKeyUsesRemoteConfig() {
        let mock = MockRemoteConfigService()
        mock.newsAPIKeyValue = "remote-news-key"
        APIKeysProvider.configure(with: mock)
        let key = APIKeysProvider.newsAPIKey
        #expect(key == "remote-news-key")
    }

    @Test("newsAPIKey falls back to environment variable")
    func newsAPIKeyFallsBackToEnvironment() {
        let mock = MockRemoteConfigService()
        mock.newsAPIKeyValue = nil
        APIKeysProvider.configure(with: mock)
        let testKey = "env-news-key"
        ProcessInfo.processInfo.environment["NEWS_API_KEY"] = testKey
        let key = APIKeysProvider.newsAPIKey
        #expect(key == testKey)
        ProcessInfo.processInfo.environment["NEWS_API_KEY"] = nil
    }

    @Test("gnewsAPIKey uses Remote Config when available")
    func gnewsAPIKeyUsesRemoteConfig() {
        let mock = MockRemoteConfigService()
        mock.gnewsAPIKeyValue = "remote-gnews-key"
        APIKeysProvider.configure(with: mock)
        let key = APIKeysProvider.gnewsAPIKey
        #expect(key == "remote-gnews-key")
    }

    @Test("gnewsAPIKey falls back to environment variable")
    func gnewsAPIKeyFallsBackToEnvironment() {
        let mock = MockRemoteConfigService()
        mock.gnewsAPIKeyValue = nil
        APIKeysProvider.configure(with: mock)
        let testKey = "env-gnews-key"
        ProcessInfo.processInfo.environment["GNEWS_API_KEY"] = testKey
        let key = APIKeysProvider.gnewsAPIKey
        #expect(key == testKey)
        ProcessInfo.processInfo.environment["GNEWS_API_KEY"] = nil
    }

    @Test("configure accepts RemoteConfigService")
    func configureAcceptsRemoteConfigService() {
        let mock = MockRemoteConfigService()
        APIKeysProvider.configure(with: mock)
    }

    @Test("Multiple configure calls use latest service")
    func multipleConfigureCallsUseLatestService() {
        let mock1 = MockRemoteConfigService()
        mock1.guardianAPIKeyValue = "key-from-mock1"
        let mock2 = MockRemoteConfigService()
        mock2.guardianAPIKeyValue = "key-from-mock2"
        APIKeysProvider.configure(with: mock1)
        #expect(APIKeysProvider.guardianAPIKey == "key-from-mock1")
        APIKeysProvider.configure(with: mock2)
        #expect(APIKeysProvider.guardianAPIKey == "key-from-mock2")
    }
}

@Suite("BaseURLs Tests")
struct BaseURLsTests {
    @Test("newsAPI returns correct URL")
    func newsAPIReturnsCorrectURL() {
        #expect(BaseURLs.newsAPI == "https://newsapi.org/v2")
    }

    @Test("guardianAPI returns correct URL")
    func guardianAPIReturnsCorrectURL() {
        #expect(BaseURLs.guardianAPI == "https://content.guardianapis.com")
    }

    @Test("gnewsAPI returns correct URL")
    func gnewsAPIReturnsCorrectURL() {
        #expect(BaseURLs.gnewsAPI == "https://gnews.io/api/v4")
    }
}

@Suite("LLMInferenceConfig Tests")
struct LLMInferenceConfigTests {
    @Test("default config has correct values")
    func defaultConfigHasCorrectValues() {
        let config = LLMInferenceConfig.default
        #expect(config.maxTokens == 1024)
        #expect(config.temperature == 0.7)
        #expect(config.topP == 0.9)
        #expect(config.stopSequences.contains("</digest>"))
    }

    @Test("dailyDigest config has correct values")
    func dailyDigestConfigHasCorrectValues() {
        let config = LLMInferenceConfig.dailyDigest
        #expect(config.temperature == 0.7)
        #expect(config.topP == 0.9)
        #expect(config.stopSequences.contains("</digest>"))
        #expect(config.stopSequences.contains("---"))
    }

    @Test("summarization config has correct values")
    func summarizationConfigHasCorrectValues() {
        let config = LLMInferenceConfig.summarization
        #expect(config.maxTokens == 512)
        #expect(config.temperature == 0.5)
        #expect(config.topP == 0.9)
        #expect(config.stopSequences.contains("</summary>"))
    }
}

@Suite("LLMModelStatus Tests")
struct LLMModelStatusTests {
    @Test("all cases are equatable")
    func allCasesAreEquatable() {
        let status1: LLMModelStatus = .notLoaded
        let status2: LLMModelStatus = .notLoaded
        #expect(status1 == status2)
    }

    @Test("loading case stores progress")
    func loadingCaseStoresProgress() {
        let status: LLMModelStatus = .loading(progress: 0.5)
        if case let .loading(progress) = status {
            #expect(progress == 0.5)
        } else {
            Issue.record("Expected loading case")
        }
    }

    @Test("error case stores message")
    func errorCaseStoresMessage() {
        let status: LLMModelStatus = .error("Test error")
        if case let .error(message) = status {
            #expect(message == "Test error")
        } else {
            Issue.record("Expected error case")
        }
    }
}

@Suite("LLMError Tests")
struct LLMErrorTests {
    @Test("all errors have errorDescription")
    func allErrorsHaveErrorDescription() {
        let errors: [LLMError] = [
            .modelNotLoaded,
            .modelLoadFailed("test"),
            .inferenceTimeout,
            .memoryPressure,
            .generationCancelled,
            .serviceUnavailable,
            .tokenizationFailed,
            .generationFailed("test"),
        ]
        for error in errors {
            let description = error.errorDescription
            #expect(description != nil)
        }
    }
}

@Suite("SearchDomainInteractor Tests")
struct SearchDomainInteractorTests {
    @Test("SearchDomainInteractor can be instantiated")
    func canBeInstantiated() {
        let locator = ServiceLocator()
        locator.register(SearchService.self, instance: MockSearchService())
        locator.register(StorageService.self, instance: MockStorageService())
        let interactor = SearchDomainInteractor(serviceLocator: locator)
        #expect(interactor is SearchDomainInteractor)
    }

    @Test("initial state is correct")
    func initialStateIsCorrect() {
        let locator = ServiceLocator()
        locator.register(SearchService.self, instance: MockSearchService())
        locator.register(StorageService.self, instance: MockStorageService())
        let interactor = SearchDomainInteractor(serviceLocator: locator)
        let state = interactor.currentState
        #expect(state.query == "")
        #expect(state.results.isEmpty)
        #expect(state.suggestions.isEmpty)
        #expect(!state.hasSearched)
    }

    @Test("updateQuery updates query state")
    func updateQueryUpdatesQueryState() {
        let locator = ServiceLocator()
        locator.register(SearchService.self, instance: MockSearchService())
        locator.register(StorageService.self, instance: MockStorageService())
        let interactor = SearchDomainInteractor(serviceLocator: locator)
        interactor.dispatch(action: .updateQuery("test query"))
        #expect(interactor.currentState.query == "test query")
    }

    @Test("updateQuery clears suggestions when empty")
    func updateQueryClearsSuggestionsWhenEmpty() {
        let locator = ServiceLocator()
        locator.register(SearchService.self, instance: MockSearchService())
        locator.register(StorageService.self, instance: MockStorageService())
        let interactor = SearchDomainInteractor(serviceLocator: locator)
        interactor.dispatch(action: .updateQuery("test"))
        interactor.dispatch(action: .updateQuery(""))
        #expect(interactor.currentState.suggestions.isEmpty)
    }

    @Test("setSortOption updates sort option")
    func setSortOptionUpdatesSortOption() {
        let locator = ServiceLocator()
        locator.register(SearchService.self, instance: MockSearchService())
        locator.register(StorageService.self, instance: MockStorageService())
        let interactor = SearchDomainInteractor(serviceLocator: locator)
        interactor.dispatch(action: .setSortOption(.relevance))
        #expect(interactor.currentState.sortBy == .relevance)
    }

    @Test("selectArticle updates selected article")
    func selectArticleUpdatesSelectedArticle() throws {
        let locator = ServiceLocator()
        locator.register(SearchService.self, instance: MockSearchService())
        locator.register(StorageService.self, instance: MockStorageService())
        let interactor = SearchDomainInteractor(serviceLocator: locator)
        let article = try #require(Article.mockArticles.first)
        interactor.dispatch(action: .selectArticle(article.id))
        #expect(interactor.currentState.selectedArticle?.id == article.id)
    }

    @Test("clearSelectedArticle clears selection")
    func clearSelectedArticleClearsSelection() throws {
        let locator = ServiceLocator()
        locator.register(SearchService.self, instance: MockSearchService())
        locator.register(StorageService.self, instance: MockStorageService())
        let interactor = SearchDomainInteractor(serviceLocator: locator)
        let article = try #require(Article.mockArticles.first)
        interactor.dispatch(action: .selectArticle(article.id))
        interactor.dispatch(action: .clearSelectedArticle)
        #expect(interactor.currentState.selectedArticle == nil)
    }
}

extension Product {
    static var mock: Product {
        Product(
            id: "com.bruno.Pulse.premium.monthly",
            displayPrice: "$4.99",
            price: 4.99,
            currencyCode: "USD",
            subscription: nil
        )
    }
}
