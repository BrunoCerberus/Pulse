import Foundation
import Security

/**
 * A generic class to persist and retrieve values from the iOS Keychain.
 *
 * This class provides a secure way to store sensitive data like API keys,
 * passwords, and other credentials using the iOS Keychain Services.
 *
 * Features:
 * - Secure storage with device-only access
 * - Automatic duplicate handling (update existing items)
 * - Comprehensive error handling
 * - Service isolation for different app components
 *
 * Security Notes:
 * - Uses kSecAttrAccessibleWhenUnlockedThisDeviceOnly for maximum security
 * - Data is only accessible when the device is unlocked
 * - Data is not backed up to iCloud or other cloud services
 * - Each service instance is isolated from others
 */
final class KeychainManager {
    // MARK: - Error Types

    /**
     * Custom error types for keychain operations.
     *
     * Provides detailed error information for debugging and user feedback.
     */
    enum KeychainError: Error, LocalizedError {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidItemFormat
        case unhandledError(status: OSStatus)

        var errorDescription: String? {
            switch self {
            case .duplicateEntry:
                "Duplicate entry found in keychain"
            case let .unknown(status):
                "Unknown keychain error: \(status)"
            case .itemNotFound:
                "Item not found in keychain"
            case .invalidItemFormat:
                "Invalid item format"
            case let .unhandledError(status):
                "Unhandled keychain error: \(status)"
            }
        }
    }

    // MARK: - Properties

    /// The service identifier for this keychain instance
    private let service: String

    /// Optional access group for sharing across app extensions
    private let accessGroup: String?

    // MARK: - Initialization

    /**
     * Initialize with a service name and optional access group.
     *
     * - Parameters:
     *   - service: The service name for the keychain items (e.g., "APIKeys", "UserCredentials")
     *   - accessGroup: Optional access group for sharing across apps/extensions
     */
    init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    // MARK: - Public Methods

    /**
     * Save a value to the keychain.
     *
     * If an item with the same key already exists, it will be updated.
     *
     * - Parameters:
     *   - value: The string value to save securely
     *   - key: The unique key to associate with the value
     * - Throws: KeychainError if the operation fails
     */
    func save(_ value: String, for key: String) throws {
        // Convert string to data for storage
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }

        // Create the keychain query with security attributes
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        // Attempt to add the item to keychain
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status != errSecSuccess else { return }

        if status == errSecDuplicateItem {
            // Item already exists, update it instead
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]

            let updateAttributes: [String: Any] = [
                kSecValueData as String: data,
            ]

            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)

            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: updateStatus)
            }
        } else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /**
     * Retrieve a value from the keychain.
     *
     * - Parameter key: The key to retrieve
     * - Returns: The stored string value
     * - Throws: KeychainError if the operation fails or item is not found
     */
    func retrieve(for key: String) throws -> String {
        // Create query to find the item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        // Convert data back to string
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.invalidItemFormat
        }

        return string
    }

    /**
     * Delete a value from the keychain.
     *
     * - Parameter key: The key to delete
     * - Throws: KeychainError if the operation fails (except for item not found)
     */
    func delete(for key: String) throws {
        // Create query to identify the item to delete
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Allow item not found errors (item was already deleted)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /**
     * Check if a key exists in the keychain.
     *
     * This method performs a lightweight check without retrieving the actual data.
     *
     * - Parameter key: The key to check
     * - Returns: True if the key exists, false otherwise
     */
    func exists(for key: String) -> Bool {
        // Create query to check existence (without returning data)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
