import EntropyCore
import FirebaseAuth

// MARK: - UserDefaults Keys

enum AuthUserKeys {
    static let hasPasskey = "pulse.userHasPasskey"
}

// MARK: - User Detection

extension FirebaseAuth.User {
    func toAuthUser() -> AuthUser? {
        let provider: AuthProvider
        if isAnonymous {
            provider = .anonymous
        } else if providerData.contains(where: { $0.providerID == "google.com" }) {
            provider = .google
        } else if providerData.contains(where: { $0.providerID == "apple.com" }) {
            // Distinguish Apple Sign-In from Passkey via the client-side flag.
            // Firebase returns `apple.com` for both, so we check whether the user
            // has a passkey registered (set at registration/sign-in time).
            let defaults = UserDefaults.standard
            provider = defaults.bool(forKey: AuthUserKeys.hasPasskey) ? .passkey : .apple
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
            provider: provider
        )
    }
}
