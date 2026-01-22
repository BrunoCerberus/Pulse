import Foundation

/**
 * Supabase configuration provider for the backend API.
 *
 * This enum provides Supabase URL and API key with fallback mechanisms
 * similar to APIKeysProvider.
 *
 * Fallback Hierarchy:
 * 1. Firebase Remote Config (primary, fetched from server)
 * 2. Environment variables (for CI/CD)
 * 3. Hardcoded defaults (for development only)
 *
 * Usage:
 * ```swift
 * let url = SupabaseConfig.url
 * let key = SupabaseConfig.anonKey
 * ```
 */
enum SupabaseConfig {
    // MARK: - Dependencies

    /// The configured remote config service (shared with APIKeysProvider)
    private static var remoteConfigService: RemoteConfigService?

    // MARK: - Configuration

    /**
     * Configure the Supabase config with a remote config service.
     *
     * - Parameter service: The remote config service to use
     */
    static func configure(with service: RemoteConfigService) {
        remoteConfigService = service
    }

    // MARK: - Supabase Credentials

    /**
     * Supabase project URL.
     *
     * The URL is read from Remote Config first, then falls back to
     * environment variables.
     */
    static var url: String {
        // 1. Try Remote Config (primary source)
        if let url = remoteConfigService?.supabaseURL, !url.isEmpty {
            return url
        }

        // 2. Fallback to environment variable (for CI/CD)
        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"], !url.isEmpty {
            return url
        }

        // 3. Log warning and return empty (will cause initialization to fail gracefully)
        Logger.shared.service("SUPABASE_URL not configured in Remote Config or environment", level: .warning)
        return ""
    }

    /**
     * Supabase anonymous (public) API key.
     *
     * This key is safe to include in the app as it only provides
     * read access controlled by Row Level Security policies.
     */
    static var anonKey: String {
        // 1. Try Remote Config (primary source)
        if let key = remoteConfigService?.supabaseAnonKey, !key.isEmpty {
            return key
        }

        // 2. Fallback to environment variable (for CI/CD)
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !key.isEmpty {
            return key
        }

        // 3. Log warning and return empty
        Logger.shared.service("SUPABASE_ANON_KEY not configured in Remote Config or environment", level: .warning)
        return ""
    }

    /**
     * Check if Supabase is properly configured.
     *
     * - Returns: `true` if both URL and anon key are available
     */
    static var isConfigured: Bool {
        !url.isEmpty && !anonKey.isEmpty
    }
}
