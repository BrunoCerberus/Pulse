import EntropyCore
import FirebaseAuth

/// Bridges Firebase's non-Sendable `User` to the app-internal `AuthUser`.
/// Lives in its own file so `LiveAuthService.swift` stays focused on the
/// auth flow itself and below the SwiftLint file-length budget.
extension FirebaseAuth.User {
    func toAuthUser() -> AuthUser? {
        let provider: AuthProvider
        if isAnonymous {
            provider = .anonymous
        } else if providerData.contains(where: { $0.providerID == "google.com" }) {
            provider = .google
        } else if providerData.contains(where: { $0.providerID == "apple.com" }) {
            provider = .apple
        } else {
            let providerIDs = providerData.map(\.providerID).joined(separator: ", ")
            Logger.shared.service("Unknown auth provider(s): \(providerIDs), defaulting to .google", level: .warning)
            provider = .google
        }

        return AuthUser(
            uid: uid,
            email: email,
            displayName: displayName,
            photoURL: photoURL,
            provider: provider,
        )
    }
}
