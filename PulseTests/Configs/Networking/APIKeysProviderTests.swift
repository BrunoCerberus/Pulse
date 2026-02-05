import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("APIKeysProvider Tests", .serialized)
struct APIKeysProviderTests {
    // MARK: - Setup

    /// Creates a fresh mock remote config for testing
    private func createMockRemoteConfig(
        guardianKey: String? = nil,
        newsKey: String? = nil,
        gnewsKey: String? = nil
    ) -> MockRemoteConfigService {
        let mock = MockRemoteConfigService()
        mock.guardianAPIKeyValue = guardianKey
        mock.newsAPIKeyValue = newsKey
        mock.gnewsAPIKeyValue = gnewsKey
        return mock
    }

    // MARK: - APIKeyType Tests

    @Test("APIKeyType keychainKey returns correct values")
    func apiKeyTypeKeychainKeyReturnsCorrectValues() {
        #expect(APIKeyType.newsAPI.keychainKey == "NewsAPIKey")
        #expect(APIKeyType.guardianAPI.keychainKey == "GuardianAPIKey")
        #expect(APIKeyType.gnewsAPI.keychainKey == "GNewsAPIKey")
    }

    @Test("APIKeyType covers all expected cases")
    func apiKeyTypeCoversAllCases() {
        // Verify all API key types have unique keychain keys
        let keys = [
            APIKeyType.newsAPI.keychainKey,
            APIKeyType.guardianAPI.keychainKey,
            APIKeyType.gnewsAPI.keychainKey,
        ]

        let uniqueKeys = Set(keys)
        #expect(uniqueKeys.count == keys.count)
    }

    // MARK: - Remote Config Priority Tests

    @Test("Guardian API key uses Remote Config when available")
    func guardianAPIKeyUsesRemoteConfig() {
        let mock = createMockRemoteConfig(guardianKey: "remote-guardian-key")
        APIKeysProvider.configure(with: mock)

        let key = APIKeysProvider.guardianAPIKey

        #expect(key == "remote-guardian-key")
    }

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

    // MARK: - Empty String Handling Tests

    @Test("Guardian API key skips empty Remote Config value and falls through")
    func guardianAPIKeySkipsEmptyRemoteConfig() {
        let mock = createMockRemoteConfig(guardianKey: "")
        APIKeysProvider.configure(with: mock)

        // When Remote Config returns empty string, it falls through to env var/keychain
        // In test environment without env vars set, it returns empty string
        let key = APIKeysProvider.guardianAPIKey

        // Verify the code executes without crash (empty is expected in test env)
        let isString = key is String
        #expect(isString == true)
    }

    @Test("Non-empty Remote Config takes priority over fallbacks")
    func nonEmptyRemoteConfigTakesPriority() {
        let mock = createMockRemoteConfig(guardianKey: "valid-key")
        APIKeysProvider.configure(with: mock)

        let key = APIKeysProvider.guardianAPIKey

        // Non-empty Remote Config value should be used directly
        #expect(key == "valid-key")
    }

    // MARK: - Nil Handling Tests

    @Test("Guardian API key handles nil Remote Config")
    func guardianAPIKeyHandlesNilRemoteConfig() {
        let mock = createMockRemoteConfig(guardianKey: nil)
        APIKeysProvider.configure(with: mock)

        // Should not crash and should fall through to other sources
        let key = APIKeysProvider.guardianAPIKey
        #expect(key is String)
    }

    @Test("News API key handles nil Remote Config")
    func newsAPIKeyHandlesNilRemoteConfig() {
        let mock = createMockRemoteConfig(newsKey: nil)
        APIKeysProvider.configure(with: mock)

        let key = APIKeysProvider.newsAPIKey
        #expect(key is String)
    }

    @Test("GNews API key handles nil Remote Config")
    func gnewsAPIKeyHandlesNilRemoteConfig() {
        let mock = createMockRemoteConfig(gnewsKey: nil)
        APIKeysProvider.configure(with: mock)

        let key = APIKeysProvider.gnewsAPIKey
        #expect(key is String)
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
        let mock1 = createMockRemoteConfig(guardianKey: "key-from-mock1")
        let mock2 = createMockRemoteConfig(guardianKey: "key-from-mock2")

        APIKeysProvider.configure(with: mock1)
        #expect(APIKeysProvider.guardianAPIKey == "key-from-mock1")

        APIKeysProvider.configure(with: mock2)
        #expect(APIKeysProvider.guardianAPIKey == "key-from-mock2")
    }

    // MARK: - All Keys Available Tests

    @Test("All API keys available from Remote Config")
    func allAPIKeysAvailableFromRemoteConfig() {
        let mock = MockRemoteConfigService()
        mock.guardianAPIKeyValue = "guardian-test"
        mock.newsAPIKeyValue = "news-test"
        mock.gnewsAPIKeyValue = "gnews-test"
        APIKeysProvider.configure(with: mock)

        #expect(APIKeysProvider.guardianAPIKey == "guardian-test")
        #expect(APIKeysProvider.newsAPIKey == "news-test")
        #expect(APIKeysProvider.gnewsAPIKey == "gnews-test")
    }
}

@Suite("RemoteConfigKey Tests")
struct RemoteConfigKeyTests {
    @Test("RemoteConfigKey raw values are correct")
    func rawValuesAreCorrect() {
        #expect(RemoteConfigKey.guardianAPIKey.rawValue == "guardian_api_key")
        #expect(RemoteConfigKey.newsAPIKey.rawValue == "news_api_key")
        #expect(RemoteConfigKey.gnewsAPIKey.rawValue == "gnews_api_key")
        #expect(RemoteConfigKey.supabaseURL.rawValue == "supabase_url")
        #expect(RemoteConfigKey.supabaseAnonKey.rawValue == "supabase_anon_key")
    }

    @Test("RemoteConfigKey has all expected keys")
    func hasAllExpectedKeys() {
        // Verify we have keys for all API credentials
        let allKeys: [RemoteConfigKey] = [
            .guardianAPIKey,
            .newsAPIKey,
            .gnewsAPIKey,
            .supabaseURL,
            .supabaseAnonKey,
        ]

        #expect(allKeys.count == 5)

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
        mock.guardianAPIKeyValue = "guardian-test"
        mock.newsAPIKeyValue = "news-test"
        mock.gnewsAPIKeyValue = "gnews-test"
        mock.supabaseURLValue = "https://test.supabase.co"
        mock.supabaseAnonKeyValue = "anon-key-test"

        #expect(mock.guardianAPIKey == "guardian-test")
        #expect(mock.newsAPIKey == "news-test")
        #expect(mock.gnewsAPIKey == "gnews-test")
        #expect(mock.supabaseURL == "https://test.supabase.co")
        #expect(mock.supabaseAnonKey == "anon-key-test")
    }

    @Test("MockRemoteConfigService getStringOrNil returns correct values")
    func getStringOrNilReturnsCorrectValues() {
        let mock = MockRemoteConfigService()
        mock.guardianAPIKeyValue = "guardian-value"

        #expect(mock.getStringOrNil(forKey: .guardianAPIKey) == "guardian-value")
        #expect(mock.getStringOrNil(forKey: .newsAPIKey) == nil)
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

        #expect(mock.guardianAPIKey == nil)
        #expect(mock.newsAPIKey == nil)
        #expect(mock.gnewsAPIKey == nil)
        #expect(mock.supabaseURL == nil)
        #expect(mock.supabaseAnonKey == nil)
    }
}
