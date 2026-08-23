import EntropyCore
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
    private nonisolated(unsafe) static var remoteConfigService: RemoteConfigService?

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
     * environment variables, and is finally gated on the `https` scheme.
     */
    static var url: String {
        let candidate = configuredURL
        // Backstop: Remote Config is a trusted component (THREAT_MODEL §2) and
        // ATS makes `URLSession.shared` fail closed on non-HTTPS, but an
        // operator misconfig or Firebase-account compromise that serves an
        // `http://` value would otherwise pass `isConfigured` and reach the
        // request builders. Refuse anything that is not a parseable `https`
        // URL so `isConfigured` stays honest.
        guard isSecureSupabaseURL(candidate) else {
            Logger.shared.service(
                "SUPABASE_URL is not a valid https URL — refusing to use it",
                level: .warning,
            )
            return ""
        }
        return candidate
    }

    /// Raw configured URL, before the `https` backstop applied in `url`.
    private static var configuredURL: String {
        // 1. Try Remote Config (primary source)
        if let url = remoteConfigService?.supabaseURL, !url.isEmpty {
            return url
        }

        // 2. Fallback to environment variable (for CI/CD and debugging only)
        #if DEBUG
            if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"], !url.isEmpty {
                return url
            }
        #endif

        // 3. Log warning and return empty (will cause initialization to fail gracefully)
        Logger.shared.service("SUPABASE_URL not configured in Remote Config or environment", level: .warning)
        return ""
    }

    /// Scheme backstop for operator-supplied URLs (Remote Config / env var).
    /// Same https-only rule as `SafeMediaURL`, inlined here because that gate
    /// is scoped to untrusted media / article URLs.
    private static func isSecureSupabaseURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme?.lowercased() == "https"
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
