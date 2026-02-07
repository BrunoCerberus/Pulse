import EntropyCore
import Foundation
@testable import Pulse
import Testing

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
