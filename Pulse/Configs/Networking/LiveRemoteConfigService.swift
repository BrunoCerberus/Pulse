import FirebaseRemoteConfig
import Foundation

/// Live implementation of RemoteConfigService using Firebase Remote Config.
///
/// Remote Config Keys (set in Firebase Console):
/// - `guardian_api_key`: Guardian API key
/// - `news_api_key`: NewsAPI.org key
/// - `gnews_api_key`: GNews API key
final class LiveRemoteConfigService: RemoteConfigService {
    // MARK: - Properties

    private let remoteConfig: RemoteConfig

    // MARK: - Initialization

    init() {
        remoteConfig = RemoteConfig.remoteConfig()
        configureSettings()
        setDefaults()
    }

    // MARK: - Configuration

    private func configureSettings() {
        let settings = RemoteConfigSettings()
        #if DEBUG
            // Fetch frequently during development
            settings.minimumFetchInterval = 0
        #else
            // Cache for 1 hour in production
            settings.minimumFetchInterval = 3600
        #endif
        remoteConfig.configSettings = settings
    }

    private func setDefaults() {
        // Set empty defaults - actual keys come from Firebase Console
        remoteConfig.setDefaults([
            RemoteConfigKey.guardianAPIKey.rawValue: "" as NSString,
            RemoteConfigKey.newsAPIKey.rawValue: "" as NSString,
            RemoteConfigKey.gnewsAPIKey.rawValue: "" as NSString,
        ])
    }

    // MARK: - RemoteConfigService

    func fetchAndActivate() async throws {
        let status = try await remoteConfig.fetchAndActivate()

        switch status {
        case .successFetchedFromRemote:
            Logger.shared.service("Remote Config: fetched from remote", level: .info)
        case .successUsingPreFetchedData:
            Logger.shared.service("Remote Config: using cached data", level: .info)
        case .error:
            Logger.shared.service("Remote Config: fetch failed", level: .error)
            throw RemoteConfigError.fetchFailed
        @unknown default:
            Logger.shared.service("Remote Config: unknown status", level: .warning)
        }
    }

    func getStringOrNil(forKey key: RemoteConfigKey) -> String? {
        let value = remoteConfig.configValue(forKey: key.rawValue).stringValue
        return value.isEmpty ? nil : value
    }

    var guardianAPIKey: String? {
        getStringOrNil(forKey: .guardianAPIKey)
    }

    var newsAPIKey: String? {
        getStringOrNil(forKey: .newsAPIKey)
    }

    var gnewsAPIKey: String? {
        getStringOrNil(forKey: .gnewsAPIKey)
    }
}
