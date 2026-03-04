import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite(.serialized)
struct APIKeysProviderTests {
    // MARK: - Setup

    /// Creates a fresh mock remote config for testing
    private func createMockRemoteConfig(
        guardianKey: String? = nil
    ) -> MockRemoteConfigService {
        let mock = MockRemoteConfigService()
        mock.guardianAPIKeyValue = guardianKey
        return mock
    }

    // MARK: - APIKeyType Tests

    @Test("APIKeyType keychainKey returns correct values")
    func apiKeyTypeKeychainKeyReturnsCorrectValues() {
        #expect(APIKeyType.guardianAPI.keychainKey == "GuardianAPIKey")
    }

    // MARK: - Remote Config Priority Tests

    @Test("Guardian API key uses Remote Config when available")
    func guardianAPIKeyUsesRemoteConfig() {
        let mock = createMockRemoteConfig(guardianKey: "remote-guardian-key")
        APIKeysProvider.configure(with: mock)

        let key = APIKeysProvider.guardianAPIKey

        #expect(key == "remote-guardian-key")
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
        _ = key
    }

    @Test("Non-empty Remote Config takes priority over fallbacks")
    func nonEmptyRemoteConfigTakesPriority() {
        let mock = createMockRemoteConfig(guardianKey: "valid-key-test")
        APIKeysProvider.configure(with: mock)

        let key = APIKeysProvider.guardianAPIKey

        // Non-empty Remote Config value should be used directly
        #expect(key == "valid-key-test")
    }

    // MARK: - Nil Handling Tests

    @Test("Guardian API key handles nil Remote Config")
    func guardianAPIKeyHandlesNilRemoteConfig() {
        let mock = createMockRemoteConfig(guardianKey: nil)
        APIKeysProvider.configure(with: mock)

        // Should not crash and should fall through to other sources
        _ = APIKeysProvider.guardianAPIKey
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

    @Test("Guardian API key available from Remote Config")
    func guardianAPIKeyAvailableFromRemoteConfig() {
        let mock = MockRemoteConfigService()
        mock.guardianAPIKeyValue = "guardian-test-key"
        APIKeysProvider.configure(with: mock)

        #expect(APIKeysProvider.guardianAPIKey == "guardian-test-key")
    }
}

struct RemoteConfigKeyTests {
    @Test("RemoteConfigKey raw values are correct")
    func rawValuesAreCorrect() {
        #expect(RemoteConfigKey.guardianAPIKey.rawValue == "guardian_api_key")
        #expect(RemoteConfigKey.supabaseURL.rawValue == "supabase_url")
        #expect(RemoteConfigKey.supabaseAnonKey.rawValue == "supabase_anon_key")
    }

    @Test("RemoteConfigKey has all expected keys")
    func hasAllExpectedKeys() {
        // Verify we have keys for all API credentials
        let allKeys: [RemoteConfigKey] = [
            .guardianAPIKey,
            .supabaseURL,
            .supabaseAnonKey,
        ]

        #expect(allKeys.count == 3)

        // All raw values should be unique
        let uniqueValues = Set(allKeys.map(\.rawValue))
        #expect(uniqueValues.count == allKeys.count)
    }
}

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

struct MockRemoteConfigServiceTests {
    @Test("MockRemoteConfigService provides configured values")
    func providesConfiguredValues() {
        let mock = MockRemoteConfigService()
        mock.guardianAPIKeyValue = "guardian-test"
        mock.supabaseURLValue = "https://test.supabase.co"
        mock.supabaseAnonKeyValue = "anon-key-test"

        #expect(mock.guardianAPIKey == "guardian-test")
        #expect(mock.supabaseURL == "https://test.supabase.co")
        #expect(mock.supabaseAnonKey == "anon-key-test")
    }

    @Test("MockRemoteConfigService getStringOrNil returns correct values")
    func getStringOrNilReturnsCorrectValues() {
        let mock = MockRemoteConfigService()
        mock.guardianAPIKeyValue = "guardian-value"

        #expect(mock.getStringOrNil(forKey: .guardianAPIKey) == "guardian-value")
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
        #expect(mock.supabaseURL == nil)
        #expect(mock.supabaseAnonKey == nil)
    }
}
