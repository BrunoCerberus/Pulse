import AuthenticationServices
import Combine
import CryptoKit
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
            Task { @MainActor in
                do {
                    guard let clientID = FirebaseApp.app()?.options.clientID else {
                        promise(.failure(AuthError.unknown("Missing Firebase client ID")))
                        return
                    }

                    let config = GIDConfiguration(clientID: clientID)
                    GIDSignIn.sharedInstance.configuration = config

                    let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
                    guard let idToken = result.user.idToken?.tokenString else {
                        promise(.failure(AuthError.invalidCredential))
                        return
                    }

                    let credential = GoogleAuthProvider.credential(
                        withIDToken: idToken,
                        accessToken: result.user.accessToken.tokenString
                    )

                    let authResult = try await Auth.auth().signIn(with: credential)
                    if let user = authResult.user.toAuthUser() {
                        promise(.success(user))
                    } else {
                        promise(.failure(AuthError.unknown("Failed to create user")))
                    }
                } catch let error as GIDSignInError where error.code == .canceled {
                    promise(.failure(AuthError.signInCancelled))
                } catch {
                    promise(.failure(AuthError.unknown(error.localizedDescription)))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func signInWithApple() -> AnyPublisher<AuthUser, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(AuthError.unknown("Service deallocated")))
                return
            }

            let nonce = self.randomNonceString()
            self.currentNonce = nonce

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email, .fullName]
            request.nonce = self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()

            // Store continuation for async handling
            Task {
                do {
                    let user = try await withCheckedThrowingContinuation { continuation in
                        self.appleSignInContinuation = continuation
                    }
                    promise(.success(user))
                } catch {
                    promise(.failure(error))
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

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
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
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        Task {
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
            provider = .google // Default fallback
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
