import Foundation

/// Remote Config keys for API credentials.
enum RemoteConfigKey: String {
    case guardianAPIKey = "guardian_api_key"
    case newsAPIKey = "news_api_key"
    case gnewsAPIKey = "gnews_api_key"
}

/// Protocol for Remote Config operations.
protocol RemoteConfigService {
    /// Fetches and activates remote config values.
    func fetchAndActivate() async throws

    /// Gets a string value, returning nil if empty or not found.
    func getStringOrNil(forKey key: RemoteConfigKey) -> String?

    /// Gets the Guardian API key from remote config.
    var guardianAPIKey: String? { get }

    /// Gets the NewsAPI key from remote config.
    var newsAPIKey: String? { get }

    /// Gets the GNews API key from remote config.
    var gnewsAPIKey: String? { get }
}

// MARK: - Errors

enum RemoteConfigError: Error, LocalizedError {
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch remote configuration"
        }
    }
}
