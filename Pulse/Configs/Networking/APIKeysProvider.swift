import Foundation

/**
 * API Keys Provider for secure credential management.
 *
 * This enum provides a centralized way to manage API keys with multiple
 * fallback mechanisms for different deployment scenarios.
 *
 * Security Features:
 * - Primary storage in Secrets.plist (gitignored)
 * - Environment variable fallback for CI/CD compatibility
 * - Keychain fallback for maximum security
 * - No hardcoded keys in source code (except default fallback)
 *
 * Fallback Hierarchy:
 * 1. Secrets.plist (primary, for development)
 * 2. Environment variables (for CI/CD)
 * 3. Keychain (for secure runtime storage)
 * 4. Default value (last resort)
 */
enum APIKeysProvider {
    // MARK: - Constants

    /// Keychain service identifier for API keys
    private static let keychainService: String = "com.bruno.Pulse.APIKeys"

    /// Key identifiers for keychain storage
    private static let newsAPIKeyKey: String = "NewsAPIKey"
    private static let guardianAPIKeyKey: String = "GuardianAPIKey"
    private static let gnewsAPIKeyKey: String = "GNewsAPIKey"

    // MARK: - Keychain Manager

    /// Shared keychain manager instance for API key storage
    private static let keychainManager: KeychainManager = .init(service: keychainService)

    // MARK: - API Keys

    /**
     * NewsAPI.org API key.
     *
     * The key is read from Secrets.plist file with fallbacks to environment variables and keychain.
     */
    static let newsAPIKey: String = {
        // First try to get from Secrets.plist
        if let apiKey = loadAPIKeyFromSecretsPlist(key: "NEWS_API_KEY"), !apiKey.isEmpty {
            return apiKey
        }

        // Fallback to environment variable (for CI/CD and debugging)
        if let apiKey = ProcessInfo.processInfo.environment["NEWS_API_KEY"], !apiKey.isEmpty {
            return apiKey
        }

        // Fallback to keychain if environment variable is not set
        do {
            return try keychainManager.retrieve(for: newsAPIKeyKey)
        } catch {
            logAPIKeyError(keyName: "NEWS_API_KEY")
            return ""
        }
    }()

    /**
     * Guardian API key.
     */
    static let guardianAPIKey: String = {
        if let apiKey = loadAPIKeyFromSecretsPlist(key: "GUARDIAN_API_KEY"), !apiKey.isEmpty {
            return apiKey
        }

        if let apiKey = ProcessInfo.processInfo.environment["GUARDIAN_API_KEY"], !apiKey.isEmpty {
            return apiKey
        }

        do {
            return try keychainManager.retrieve(for: guardianAPIKeyKey)
        } catch {
            return ""
        }
    }()

    /**
     * GNews API key.
     */
    static let gnewsAPIKey: String = {
        if let apiKey = loadAPIKeyFromSecretsPlist(key: "GNEWS_API_KEY"), !apiKey.isEmpty {
            return apiKey
        }

        if let apiKey = ProcessInfo.processInfo.environment["GNEWS_API_KEY"], !apiKey.isEmpty {
            return apiKey
        }

        do {
            return try keychainManager.retrieve(for: gnewsAPIKeyKey)
        } catch {
            return ""
        }
    }()

    // MARK: - Public Methods

    /**
     * Set an API key in keychain.
     *
     * This method allows runtime updates of API keys,
     * useful for user-provided keys or key rotation.
     *
     * - Parameters:
     *   - apiKey: The API key to store securely
     *   - keyType: The type of API key to store
     * - Throws: KeychainError if the operation fails
     */
    static func setAPIKey(_ apiKey: String, for keyType: APIKeyType) throws {
        try keychainManager.save(apiKey, for: keyType.keychainKey)
    }

    /**
     * Get an API key from keychain.
     *
     * - Parameter keyType: The type of API key to retrieve
     * - Returns: The stored API key
     * - Throws: KeychainError if the key is not found or operation fails
     */
    static func getAPIKey(for keyType: APIKeyType) throws -> String {
        try keychainManager.retrieve(for: keyType.keychainKey)
    }

    /**
     * Check if an API key exists in keychain.
     *
     * - Parameter keyType: The type of API key to check
     * - Returns: True if the key exists, false otherwise
     */
    static func hasAPIKey(for keyType: APIKeyType) -> Bool {
        keychainManager.exists(for: keyType.keychainKey)
    }

    /**
     * Remove an API key from keychain.
     *
     * - Parameter keyType: The type of API key to remove
     * - Throws: KeychainError if the operation fails
     */
    static func removeAPIKey(for keyType: APIKeyType) throws {
        try keychainManager.delete(for: keyType.keychainKey)
    }

    // MARK: - Private Methods

    /**
     * Load API key from Secrets.plist file.
     *
     * - Parameter key: The key name in the plist
     * - Returns: The API key if found, nil otherwise
     */
    private static func loadAPIKeyFromSecretsPlist(key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist[key] as? String
        else {
            return nil
        }
        return apiKey
    }

    /**
     * Log a helpful error message when API key is not found.
     */
    private static func logAPIKeyError(keyName: String) {
        Logger.shared.service("""
        \(keyName) not found in Secrets.plist, environment variables, or keychain.

        To fix this:
        1. Add \(keyName) to Secrets.plist file, OR
        2. Set the \(keyName) environment variable in your build configuration, OR
        3. Call APIKeysProvider.setAPIKey("your_api_key", for: .\(keyName.lowercased())) before accessing the key

        Current environment: \(ProcessInfo.processInfo.environment.keys.filter { $0.contains("API") })
        """, level: .error)
    }

    // MARK: - Testing Support

    /**
     * Get the NewsAPI key with fresh evaluation (for testing).
     *
     * This method re-evaluates the fallback hierarchy each time it's called,
     * making it suitable for testing different scenarios.
     *
     * - Returns: The API key from the current fallback hierarchy
     */
    static func getCurrentNewsAPIKey() -> String {
        if let apiKey = loadAPIKeyFromSecretsPlist(key: "NEWS_API_KEY"), !apiKey.isEmpty {
            return apiKey
        }

        if let apiKey = ProcessInfo.processInfo.environment["NEWS_API_KEY"], !apiKey.isEmpty {
            return apiKey
        }

        do {
            return try keychainManager.retrieve(for: newsAPIKeyKey)
        } catch {
            logAPIKeyError(keyName: "NEWS_API_KEY")
            return ""
        }
    }
}

// MARK: - API Key Type

enum APIKeyType {
    case newsAPI
    case guardianAPI
    case gnewsAPI

    var keychainKey: String {
        switch self {
        case .newsAPI: "NewsAPIKey"
        case .guardianAPI: "GuardianAPIKey"
        case .gnewsAPI: "GNewsAPIKey"
        }
    }
}
