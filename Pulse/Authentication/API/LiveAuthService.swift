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
    private var appleSignInContinuation: CheckedContinuation<AuthUser, Error>?

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
        Future { promise in
            let promise = UncheckedSendableBox(value: promise)
            Task { @MainActor in
                do {
                    guard let clientID = FirebaseApp.app()?.options.clientID else {
                        promise.value(.failure(AuthError.unknown("Missing Firebase client ID")))
                        return
                    }

                    let config = GIDConfiguration(clientID: clientID)
                    GIDSignIn.sharedInstance.configuration = config

                    let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
                    guard let idToken = result.user.idToken?.tokenString else {
                        promise.value(.failure(AuthError.invalidCredential))
                        return
                    }

                    let credential = GoogleAuthProvider.credential(
                        withIDToken: idToken,
                        accessToken: result.user.accessToken.tokenString
                    )

                    let authResult = try await Auth.auth().signIn(with: credential)
                    if let user = authResult.user.toAuthUser() {
                        promise.value(.success(user))
                    } else {
                        promise.value(.failure(AuthError.unknown("Failed to create user")))
                    }
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

            let nonce: String
            do {
                nonce = try self.randomNonceString()
            } catch {
                promise(.failure(error))
                return
            }
            self.currentNonce = nonce

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email, .fullName]
            request.nonce = self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()

            // Store continuation for async handling
            let promise = UncheckedSendableBox(value: promise)
            let weakSelf = WeakRef(self)
            Task {
                do {
                    let user = try await withCheckedThrowingContinuation { continuation in
                        weakSelf.object?.appleSignInContinuation = continuation
                    }
                    promise.value(.success(user))
                } catch {
                    promise.value(.failure(error))
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
            appleSignInContinuation?.resume(throwing: AuthError.invalidCredential)
            cleanupAppleSignInState()
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        Task {
            defer { cleanupAppleSignInState() }
            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                if let user = authResult.user.toAuthUser() {
                    appleSignInContinuation?.resume(returning: user)
                } else {
                    appleSignInContinuation?.resume(throwing: AuthError.unknown("Failed to create user"))
                }
            } catch {
                appleSignInContinuation?.resume(throwing: AuthError.unknown(error.localizedDescription))
            }
        }
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: Error) {
        if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
            appleSignInContinuation?.resume(throwing: AuthError.signInCancelled)
        } else {
            appleSignInContinuation?.resume(throwing: AuthError.unknown(error.localizedDescription))
        }
        cleanupAppleSignInState()
    }

    private func cleanupAppleSignInState() {
        currentNonce = nil
        appleSignInContinuation = nil
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
