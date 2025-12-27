import Foundation

struct AuthDomainState: Equatable {
    var isLoading: Bool
    var error: String?
    var user: AuthUser?

    static var initial: AuthDomainState {
        AuthDomainState(
            isLoading: false,
            error: nil,
            user: nil
        )
    }
}
