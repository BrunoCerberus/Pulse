import Foundation

/// Remote Config keys for API credentials and feature flags.
enum RemoteConfigKey: String {
    case newsAPIKey = "news_api_key"
    case gnewsAPIKey = "gnews_api_key"
    case supabaseURL = "supabase_url"
    case supabaseAnonKey = "supabase_anon_key"
    case forYouEnabled = "for_you_enabled"
}

/// Protocol for Remote Config operations.
protocol RemoteConfigService: Sendable {
    /// Fetches and activates remote config values.
    func fetchAndActivate() async throws

    /// Gets a string value, returning nil if empty or not found.
    func getStringOrNil(forKey key: RemoteConfigKey) -> String?

    /// Gets a boolean feature flag, defaulting to `false` if missing.
    func getBool(forKey key: RemoteConfigKey) -> Bool

    /// Gets the NewsAPI key from remote config.
    var newsAPIKey: String? { get }

    /// Gets the GNews API key from remote config.
    var gnewsAPIKey: String? { get }

    /// Gets the Supabase project URL from remote config.
    var supabaseURL: String? { get }

    /// Gets the Supabase anonymous key from remote config.
    var supabaseAnonKey: String? { get }

    /// Whether the on-device personalized "For You" feed is enabled.
    var isForYouEnabled: Bool { get }
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
