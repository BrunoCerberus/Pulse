import Foundation

/// Domain state for Passkey Management.
struct PasskeyManagementDomainState: Equatable {
    var passkeys: [String]
    var isLoading: Bool
    var error: String?

    static var initial: PasskeyManagementDomainState {
        PasskeyManagementDomainState(
            passkeys: [],
            isLoading: false,
            error: nil
        )
    }
}
