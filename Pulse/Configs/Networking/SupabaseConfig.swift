import Foundation

/**
 * Supabase configuration provider for the backend API.
 *
 * This enum provides the Supabase project URL with fallback mechanisms.
 * The Edge Functions API is public and does not require authentication.
 *
 * Fallback Hierarchy:
 * 1. Firebase Remote Config (primary, fetched from server)
 * 2. Environment variables (for CI/CD)
 *
 * Usage:
 * ```swift
 * let url = SupabaseConfig.url
 * if SupabaseConfig.isConfigured {
 *     // Use Supabase Edge Functions
 * }
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

    // MARK: - Supabase URL

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
     * Check if Supabase is properly configured.
     *
     * - Returns: `true` if the URL is available (auth key not required for Edge Functions)
     */
    static var isConfigured: Bool {
        !url.isEmpty
    }
}
