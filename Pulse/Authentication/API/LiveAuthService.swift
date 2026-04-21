import AuthenticationServices
import Combine
import CryptoKit
import EntropyCore
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

final class LiveAuthService: NSObject, AuthService {
    private let authStateSubject = CurrentValueSubject<AuthUser?, Never>(nil)
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private var appleCredentialContinuation: CheckedContinuation<AuthCredential, Error>?

    var authStatePublisher: AnyPublisher<AuthUser?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }

    var currentUser: AuthUser? {
        authStateSubject.value
    }

    override init() {
        super.init()
        setupAuthStateListener()
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.authStateSubject.send(user?.toAuthUser())
        }
    }

    func signInWithGoogle(presenting viewController: UIViewController) -> AnyPublisher<AuthUser, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(AuthError.unknown("Service deallocated")))
                return
            }
            let promise = UncheckedSendableBox(value: promise)
            let weakSelf = WeakRef(self)
            Task { @MainActor in
                guard let service = weakSelf.object else {
                    promise.value(.failure(AuthError.unknown("Service deallocated")))
                    return
                }
                do {
                    let credential = try await service.obtainGoogleCredential(presenting: viewController)
                    let authResult = try await Auth.auth().signIn(with: credential)
                    if let user = authResult.user.toAuthUser() {
                        promise.value(.success(user))
                    } else {
                        promise.value(.failure(AuthError.unknown("Failed to create user")))
                    }
                } catch let error as AuthError {
                    promise.value(.failure(error))
                } catch let error as GIDSignInError where error.code == .canceled {
                    promise.value(.failure(AuthError.signInCancelled))
                } catch {
                    promise.value(.failure(AuthError.unknown(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Apple Sign-In

    /// Apple Sign-In requires additional setup before it will work:
    /// 1. Enroll in Apple Developer Program ($99/year)
    /// 2. Enable "Sign in with Apple" capability for App ID in Apple Developer Portal
    /// 3. Create a Sign in with Apple key (Keys section) and download the .p8 file
    /// 4. In Firebase Console > Authentication > Sign-in method:
    ///    - Add Apple provider
    ///    - Enter Services ID (bundle ID: com.bruno.Pulse-News)
    ///    - Enter Apple Team ID (from Apple Developer Portal > Membership)
    ///    - Enter Key ID and upload the private key (.p8 file)
    func signInWithApple() -> AnyPublisher<AuthUser, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(AuthError.unknown("Service deallocated")))
                return
            }
            let promise = UncheckedSendableBox(value: promise)
            let weakSelf = WeakRef(self)
            Task { @MainActor in
                guard let service = weakSelf.object else {
                    promise.value(.failure(AuthError.unknown("Service deallocated")))
                    return
                }
                do {
                    let credential = try await service.obtainAppleCredential()
                    let authResult = try await Auth.auth().signIn(with: credential)
                    if let user = authResult.user.toAuthUser() {
                        promise.value(.success(user))
                    } else {
                        promise.value(.failure(AuthError.unknown("Failed to create user")))
                    }
                } catch let error as AuthError {
                    promise.value(.failure(error))
                } catch {
                    promise.value(.failure(AuthError.unknown(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func signOut() -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try Auth.auth().signOut()
                promise(.success(()))
            } catch {
                promise(.failure(AuthError.unknown(error.localizedDescription)))
            }
        }
        .eraseToAnyPublisher()
    }

    func deleteAccount(presenting viewController: UIViewController) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(AuthError.unknown("Service deallocated")))
                return
            }
            let promise = UncheckedSendableBox(value: promise)
            let weakSelf = WeakRef(self)
            Task { @MainActor in
                guard let service = weakSelf.object else {
                    promise.value(.failure(AuthError.unknown("Service deallocated")))
                    return
                }
                do {
                    try await service.performDelete(presenting: viewController)
                    promise.value(.success(()))
                } catch let error as AuthError {
                    promise.value(.failure(error))
                } catch let error as GIDSignInError where error.code == .canceled {
                    promise.value(.failure(AuthError.signInCancelled))
                } catch {
                    promise.value(.failure(AuthError.unknown(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Credential Helpers

    @MainActor
    private func obtainGoogleCredential(presenting viewController: UIViewController) async throws -> AuthCredential {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.unknown("Missing Firebase client ID")
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidCredential
        }
        return GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
    }

    @MainActor
    private func obtainAppleCredential() async throws -> AuthCredential {
        let nonce = try randomNonceString()
        currentNonce = nonce

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()

        return try await withCheckedThrowingContinuation { continuation in
            appleCredentialContinuation = continuation
        }
    }

    // MARK: - Delete Flow

    @MainActor
    private func performDelete(presenting viewController: UIViewController) async throws {
        guard Auth.auth().currentUser != nil else {
            throw AuthError.noCurrentUser
        }

        do {
            try await deleteCurrentFirebaseUser()
        } catch {
            let nsError = error as NSError
            guard AuthErrorCode(rawValue: nsError.code) == .requiresRecentLogin else {
                throw error
            }

            let credential = try await freshCredentialForCurrentUser(presenting: viewController)
            try await reauthenticateCurrentFirebaseUser(with: credential)
            try await deleteCurrentFirebaseUser()
        }
    }

    /// Wraps Firebase's callback-based `delete` so we never hold a non-Sendable `User`
    /// reference across an `await`, which Swift 6.2 strict concurrency flags as a data race.
    @MainActor
    private func deleteCurrentFirebaseUser() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let user = Auth.auth().currentUser else {
                continuation.resume(throwing: AuthError.noCurrentUser)
                return
            }
            user.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    @MainActor
    private func reauthenticateCurrentFirebaseUser(with credential: AuthCredential) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let user = Auth.auth().currentUser else {
                continuation.resume(throwing: AuthError.noCurrentUser)
                return
            }
            user.reauthenticate(with: credential) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    @MainActor
    private func freshCredentialForCurrentUser(
        presenting viewController: UIViewController
    ) async throws -> AuthCredential {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noCurrentUser
        }
        let isGoogle = user.providerData.contains(where: { $0.providerID == "google.com" })
        let isApple = user.providerData.contains(where: { $0.providerID == "apple.com" })
        if isGoogle {
            return try await obtainGoogleCredential(presenting: viewController)
        }
        if isApple {
            return try await obtainAppleCredential()
        }
        throw AuthError.unknown("Unknown auth provider for re-authentication")
    }

    // MARK: - Apple Sign-In Helpers

    private func randomNonceString(length: Int = 32) throws -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            throw AuthError.unknown("Unable to generate secure nonce (OSStatus: \(errorCode))")
        }
        return Data(randomBytes).base64EncodedString()
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension LiveAuthService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            appleCredentialContinuation?.resume(throwing: AuthError.invalidCredential)
            cleanupAppleSignInState()
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        appleCredentialContinuation?.resume(returning: credential)
        cleanupAppleSignInState()
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: Error) {
        if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
            appleCredentialContinuation?.resume(throwing: AuthError.signInCancelled)
        } else {
            appleCredentialContinuation?.resume(throwing: AuthError.unknown(error.localizedDescription))
        }
        cleanupAppleSignInState()
    }

    private func cleanupAppleSignInState() {
        currentNonce = nil
        appleCredentialContinuation = nil
    }
}

// MARK: - Firebase User Extension

private extension FirebaseAuth.User {
    func toAuthUser() -> AuthUser? {
        let provider: AuthProvider
        if providerData.contains(where: { $0.providerID == "google.com" }) {
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
            provider: provider
        )
    }
}
