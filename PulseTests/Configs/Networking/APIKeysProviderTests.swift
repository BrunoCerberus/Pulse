import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("APIKeysProvider Tests", .serialized)
struct APIKeysProviderTests {
    // MARK: - Setup

    /// Creates a fresh mock remote config for testing
    private func createMockRemoteConfig(
        newsKey: String? = nil,
        gnewsKey: String? = nil
    ) -> MockRemoteConfigService {
        let mock = MockRemoteConfigService()
        mock.newsAPIKeyValue = newsKey
        mock.gnewsAPIKeyValue = gnewsKey
        return mock
    }

    // MARK: - APIKeyType Tests

    @Test("APIKeyType keychainKey returns correct values")
    func apiKeyTypeKeychainKeyReturnsCorrectValues() {
        #expect(APIKeyType.newsAPI.keychainKey == "NewsAPIKey")
        #expect(APIKeyType.gnewsAPI.keychainKey == "GNewsAPIKey")
    }

    @Test("APIKeyType covers all expected cases")
    func apiKeyTypeCoversAllCases() {
        // Verify all API key types have unique keychain keys
        let keys = [
            APIKeyType.newsAPI.keychainKey,
            APIKeyType.gnewsAPI.keychainKey,
        ]

        let uniqueKeys = Set(keys)
        #expect(uniqueKeys.count == keys.count)
    }

    // MARK: - Remote Config Priority Tests

    @Test("News API key uses Remote Config when available")
    func newsAPIKeyUsesRemoteConfig() {
        let mock = createMockRemoteConfig(newsKey: "remote-news-key")
        APIKeysProvider.configure(with: mock)

        let key = APIKeysProvider.newsAPIKey

        #expect(key == "remote-news-key")
    }

    @Test("GNews API key uses Remote Config when available")
    func gnewsAPIKeyUsesRemoteConfig() {
        let mock = createMockRemoteConfig(gnewsKey: "remote-gnews-key")
        APIKeysProvider.configure(with: mock)

        let key = APIKeysProvider.gnewsAPIKey

        #expect(key == "remote-gnews-key")
    }

    // MARK: - Nil Handling Tests

    @Test("News API key handles nil Remote Config")
    func newsAPIKeyHandlesNilRemoteConfig() {
        let mock = createMockRemoteConfig(newsKey: nil)
        APIKeysProvider.configure(with: mock)

        _ = APIKeysProvider.newsAPIKey
    }

    @Test("GNews API key handles nil Remote Config")
    func gnewsAPIKeyHandlesNilRemoteConfig() {
        let mock = createMockRemoteConfig(gnewsKey: nil)
        APIKeysProvider.configure(with: mock)

        _ = APIKeysProvider.gnewsAPIKey
    }

    // MARK: - getCurrentNewsAPIKey Tests

    @Test("getCurrentNewsAPIKey returns computed value")
    func getCurrentNewsAPIKeyReturnsComputedValue() {
        let mock = createMockRemoteConfig(newsKey: "test-news-key")
        APIKeysProvider.configure(with: mock)

        let key = APIKeysProvider.getCurrentNewsAPIKey()

        #expect(key == "test-news-key")
    }

    @Test("getCurrentNewsAPIKey reflects Remote Config changes")
    func getCurrentNewsAPIKeyReflectsChanges() {
        let mock = createMockRemoteConfig(newsKey: "initial-key")
        APIKeysProvider.configure(with: mock)

        let initialKey = APIKeysProvider.getCurrentNewsAPIKey()
        #expect(initialKey == "initial-key")

        // Update the mock
        mock.newsAPIKeyValue = "updated-key"

        let updatedKey = APIKeysProvider.getCurrentNewsAPIKey()
        #expect(updatedKey == "updated-key")
    }

    // MARK: - Configuration Tests

    @Test("Configure accepts RemoteConfigService")
    func configureAcceptsRemoteConfigService() {
        let mock = MockRemoteConfigService()

        // Should not throw
        APIKeysProvider.configure(with: mock)
    }

    @Test("Multiple configure calls use latest service")
    func multipleConfigureCallsUseLatestService() {
        let mock1 = createMockRemoteConfig(newsKey: "key-from-mock1")
        let mock2 = createMockRemoteConfig(newsKey: "key-from-mock2")

        APIKeysProvider.configure(with: mock1)
        #expect(APIKeysProvider.newsAPIKey == "key-from-mock1")

        APIKeysProvider.configure(with: mock2)
        #expect(APIKeysProvider.newsAPIKey == "key-from-mock2")
    }

    // MARK: - All Keys Available Tests

    @Test("All API keys available from Remote Config")
    func allAPIKeysAvailableFromRemoteConfig() {
        let mock = MockRemoteConfigService()
        mock.newsAPIKeyValue = "news-test-key"
        mock.gnewsAPIKeyValue = "gnews-test-key"
        APIKeysProvider.configure(with: mock)

        #expect(APIKeysProvider.newsAPIKey == "news-test-key")
        #expect(APIKeysProvider.gnewsAPIKey == "gnews-test-key")
    }
}

@Suite("RemoteConfigKey Tests")
struct RemoteConfigKeyTests {
    @Test("RemoteConfigKey raw values are correct")
    func rawValuesAreCorrect() {
        #expect(RemoteConfigKey.newsAPIKey.rawValue == "news_api_key")
        #expect(RemoteConfigKey.gnewsAPIKey.rawValue == "gnews_api_key")
        #expect(RemoteConfigKey.supabaseURL.rawValue == "supabase_url")
        #expect(RemoteConfigKey.supabaseAnonKey.rawValue == "supabase_anon_key")
    }

    @Test("RemoteConfigKey has all expected keys")
    func hasAllExpectedKeys() {
        // Verify we have keys for all API credentials
        let allKeys: [RemoteConfigKey] = [
            .newsAPIKey,
            .gnewsAPIKey,
            .supabaseURL,
            .supabaseAnonKey,
        ]

        #expect(allKeys.count == 4)

        // All raw values should be unique
        let uniqueValues = Set(allKeys.map(\.rawValue))
        #expect(uniqueValues.count == allKeys.count)
    }
}

@Suite("RemoteConfigError Tests")
struct RemoteConfigErrorTests {
    @Test("RemoteConfigError fetchFailed has description")
    func fetchFailedHasDescription() throws {
        let error = RemoteConfigError.fetchFailed

        let description = try #require(error.errorDescription)
        #expect(!description.isEmpty)
    }

    @Test("RemoteConfigError conforms to LocalizedError")
    func conformsToLocalizedError() {
        let error: LocalizedError = RemoteConfigError.fetchFailed

        #expect(error.errorDescription != nil)
    }
}

@Suite("MockRemoteConfigService Tests")
struct MockRemoteConfigServiceTests {
    @Test("MockRemoteConfigService provides configured values")
    func providesConfiguredValues() {
        let mock = MockRemoteConfigService()
        mock.newsAPIKeyValue = "news-test"
        mock.gnewsAPIKeyValue = "gnews-test"
        mock.supabaseURLValue = "https://test.supabase.co"
        mock.supabaseAnonKeyValue = "anon-key-test"

        #expect(mock.newsAPIKey == "news-test")
        #expect(mock.gnewsAPIKey == "gnews-test")
        #expect(mock.supabaseURL == "https://test.supabase.co")
        #expect(mock.supabaseAnonKey == "anon-key-test")
    }

    @Test("MockRemoteConfigService getStringOrNil returns correct values")
    func getStringOrNilReturnsCorrectValues() {
        let mock = MockRemoteConfigService()
        mock.newsAPIKeyValue = "news-value"

        #expect(mock.getStringOrNil(forKey: .newsAPIKey) == "news-value")
        #expect(mock.getStringOrNil(forKey: .gnewsAPIKey) == nil)
    }

    @Test("MockRemoteConfigService fetchAndActivate succeeds by default")
    func fetchAndActivateSucceedsByDefault() async throws {
        let mock = MockRemoteConfigService()

        // Should not throw
        try await mock.fetchAndActivate()
    }

    @Test("MockRemoteConfigService can simulate fetch failure")
    func canSimulateFetchFailure() async {
        let mock = MockRemoteConfigService()
        mock.shouldThrowOnFetch = true

        do {
            try await mock.fetchAndActivate()
            Issue.record("Expected fetchAndActivate to throw")
        } catch {
            #expect(error is RemoteConfigError)
        }
    }

    @Test("MockRemoteConfigService returns nil for unconfigured keys")
    func returnsNilForUnconfiguredKeys() {
        let mock = MockRemoteConfigService()

        #expect(mock.newsAPIKey == nil)
        #expect(mock.gnewsAPIKey == nil)
        #expect(mock.supabaseURL == nil)
        #expect(mock.supabaseAnonKey == nil)
    }
}
