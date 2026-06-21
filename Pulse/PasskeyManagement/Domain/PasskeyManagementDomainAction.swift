import Foundation

/// Actions dispatched to `PasskeyManagementDomainInteractor`.
enum PasskeyManagementDomainAction: Equatable {
    /// Load available passkeys from the device. Dispatched on view appear.
    case loadPasskeys

    /// Delete a single passkey by username. Triggered by swipe-to-delete on a row.
    case deletePasskey(username: String)

    /// Register a new passkey for the current user.
    case registerPasskey

    /// Clear any displayed error.
    case clearError
}
