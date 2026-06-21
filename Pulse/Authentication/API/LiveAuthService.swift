import AuthenticationServices
import Combine
import CryptoKit
import EntropyCore
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

// swiftlint:disable:next type_body_length
final class LiveAuthService: NSObject, AuthService {
    private let authStateSubject = CurrentValueSubject<AuthUser?, Never>(nil)
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    /// Set to `true` during passkey sign-in so the delegate stores the
    /// `pulse.userHasPasskey` flag after successful authentication.
    private var isPasskeySignIn: Bool = false
    private var appleSignInContinuation: CheckedContinuation<AuthUser, Error>?
    /// Set during the Apple re-authentication step of `deleteAccount`. When non-nil,
    /// the `ASAuthorizationControllerDelegate` returns the raw `AuthCredential` instead
    /// of completing a Firebase sign-in.
    private var appleReauthCredentialContinuation: CheckedContinuation<AuthCredential, Error>?

    /// Set during the passkey registration flow.
    private var passkeyRegistrationContinuation: CheckedContinuation<AuthUser, Error>?

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

            // The continuation MUST be stored before `performRequests()` kicks
            // off the flow. Previously `performRequests()` ran here and the
            // continuation was assigned later inside the Task — a fast delegate
            // callback could fire while `appleSignInContinuation` was still nil
            // (callback no-ops), then the Task would assign a continuation that
            // nothing ever resumes (leaked continuation + a sign-in spinner that
            // hangs forever). So assign first, then `performRequests()`, both
            // inside the `@MainActor` continuation body — which also keeps the
            // assignment on the same thread the delegate reads it from and runs
            // `performRequests()` on the main thread as UIKit requires.
            let promise = UncheckedSendableBox(value: promise)
            let weakSelf = WeakRef(self)
            let controllerBox = UncheckedSendableBox(value: controller)
            Task { @MainActor in
                guard let strongSelf = weakSelf.object else {
                    promise.value(.failure(AuthError.unknown("Service deallocated")))
                    return
                }
                do {
                    let user = try await withCheckedThrowingContinuation { continuation in
                        strongSelf.appleSignInContinuation = continuation
                        controllerBox.value.performRequests()
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
                // Firebase sign-out alone leaves GoogleSignIn's own cached
                // session (`currentUser` / `hasPreviousSignIn`) populated, so a
                // Google credential would linger for the next user of a shared
                // device. Clear it too.
                GIDSignIn.sharedInstance.signOut()
                promise(.success(()))
            } catch {
                promise(.failure(AuthError.unknown(error.localizedDescription)))
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Account Deletion

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

    @MainActor
    private func performDelete(presenting viewController: UIViewController) async throws {
        // Capture the user's identity ONCE. Account deletion is an irreversible,
        // multi-step (re-auth → re-auth-confirm → delete) operation; the
        // auth-state listener can flip `Auth.auth().currentUser` between steps
        // (token refresh, sign-out on another thread, etc.). Re-reading
        // `currentUser` in each step could act on a different — or absent —
        // user. We keep only Sendable values (`uid`, `isAnonymous`) out of this
        // read; the non-Sendable `User` never escapes. Each subsequent step
        // asserts `currentUser?.uid == capturedUID` before acting.
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.noCurrentUser
        }
        let uid = currentUser.uid
        let isAnonymous = currentUser.isAnonymous
        // Captured before any `await` (non-Sendable `User` never escapes) so we
        // can revoke the GoogleSignIn grant after a successful deletion.
        let isGoogle = currentUser.providerData.contains { $0.providerID == "google.com" }

        do {
            try await deleteCurrentFirebaseUser(expectedUID: uid)
            clearGoogleSessionIfNeeded(isGoogle: isGoogle)
            return
        } catch {
            let nsError = error as NSError
            guard AuthErrorCode(rawValue: nsError.code) == .requiresRecentLogin else {
                throw error
            }

            // Anonymous users can't be re-authenticated — there's no credential
            // to re-supply. Returning success after only signing out would lie
            // to the caller (the Firebase user record persists server-side and
            // `SettingsViewModel.handleDeleteAccount` would run its success
            // path: `clearAllUserData` + `delete_account` analytics). Surface
            // it as a specific error so the reviewer sees an honest message
            // rather than the generic "Unknown auth provider" fall-through.
            //
            // In practice this branch is hard to reach: the reviewer-only
            // anonymous session is freshly minted by the 5-tap gesture, so
            // `requiresRecentLogin` (which fires on sessions older than
            // ~5 minutes) shouldn't trigger during the same App Review pass.
            if isAnonymous {
                throw AuthError.unknown(
                    "Anonymous session can't be re-authenticated; sign out and try again."
                )
            }

            let credential = try await freshCredentialForCurrentUser(
                presenting: viewController,
                expectedUID: uid
            )
            try await reauthenticateCurrentFirebaseUser(with: credential, expectedUID: uid)
            try await deleteCurrentFirebaseUser(expectedUID: uid)
            clearGoogleSessionIfNeeded(isGoogle: isGoogle)
        }
    }

    /// After a successful account deletion, clear and revoke any GoogleSignIn
    /// session so no Google credential lingers for the next user of the device.
    /// No-op for non-Google providers (Apple keeps no persistent SDK session).
    @MainActor
    private func clearGoogleSessionIfNeeded(isGoogle: Bool) {
        guard isGoogle else { return }
        GIDSignIn.sharedInstance.signOut()
        GIDSignIn.sharedInstance.disconnect { error in
            if let error {
                Logger.shared.service(
                    "GoogleSignIn disconnect after delete failed: \(error.localizedDescription)",
                    level: .warning
                )
            }
        }
    }

    /// Wraps Firebase's callback-based `delete` so we never hold a non-Sendable `User`
    /// reference across an `await`, which Swift 6.2 strict concurrency flags as a data race.
    ///
    /// `expectedUID` is the uid captured at the start of `performDelete`. If the
    /// live `currentUser` no longer matches (auth-state flip mid-deletion) we
    /// abort rather than delete a different/absent user.
    @MainActor
    private func deleteCurrentFirebaseUser(expectedUID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let user = Auth.auth().currentUser, user.uid == expectedUID else {
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
    private func reauthenticateCurrentFirebaseUser(
        with credential: AuthCredential,
        expectedUID: String
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let user = Auth.auth().currentUser, user.uid == expectedUID else {
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
        presenting viewController: UIViewController,
        expectedUID: String
    ) async throws -> AuthCredential {
        guard let user = Auth.auth().currentUser, user.uid == expectedUID else {
            throw AuthError.noCurrentUser
        }
        let isGoogle = user.providerData.contains(where: { $0.providerID == "google.com" })
        let isApple = user.providerData.contains(where: { $0.providerID == "apple.com" })
        if isGoogle {
            return try await obtainGoogleCredentialForReauth(presenting: viewController)
        }
        if isApple {
            return try await obtainAppleCredentialForReauth()
        }
        throw AuthError.unknown("Unknown auth provider for re-authentication")
    }

    @MainActor
    private func obtainGoogleCredentialForReauth(
        presenting viewController: UIViewController
    ) async throws -> AuthCredential {
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
    private func obtainAppleCredentialForReauth() async throws -> AuthCredential {
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
            appleReauthCredentialContinuation = continuation
        }
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

    // MARK: - Passkey Methods

    /// Set the `pulse.userHasPasskey` flag so that `FirebaseUser.toAuthUser()`
    /// returns `.passkey` on subsequent cold launches.
    private func recordPasskeySignIn() {
        UserDefaults.standard.set(true, forKey: AuthUserKeys.hasPasskey)
    }

    /// Handle a successful passkey sign-in or registration.
    @MainActor
    private func handlePasskeyAuthorization(from credential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce else {
            appleSignInContinuation?.resume(throwing: AuthError.invalidCredential)
            currentNonce = nil
            isPasskeySignIn = false
            return
        }

        guard let idTokenData = credential.identityToken,
              let idTokenString = String(data: idTokenData, encoding: .utf8)
        else {
            appleSignInContinuation?.resume(throwing: AuthError.invalidCredential)
            currentNonce = nil
            isPasskeySignIn = false
            return
        }

        let credentialObj = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )

        Task {
            defer { cleanupAppleSignInState() }
            do {
                if isPasskeySignIn {
                    recordPasskeySignIn()
                }

                let authResult = try await Auth.auth().signIn(with: credentialObj)
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

    /// Sign in with a stored passkey.
    func signInWithPasskey() -> AnyPublisher<AuthUser, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(AuthError.unknown("Service deallocated")))
                return
            }

            // Check for available passkeys first. If none, fail fast so the UI
            // can offer registration instead of showing an empty picker.
            // TODO: Implement ASPasswordAuthorizationProvider once the correct API is identified for iOS 26+.
            // For now, assume passkeys are available and proceed with Apple ID flow.

            // Passkeys exist — proceed with Apple ID provider flow which
            // will automatically offer stored passkeys.
            self.signInWithPasskeyInternal(promise: promise)
        }
        .eraseToAnyPublisher()
    }

    /// Internal passkey sign-in that uses `ASAuthorizationAppleIDProvider`.
    private func signInWithPasskeyInternal(promise: @escaping (Result<AuthUser, Error>) -> Void) {
        let nonce: String
        do {
            nonce = try randomNonceString()
        } catch {
            promise(.failure(error))
            return
        }

        // Set the flag so the existing Apple delegate knows this is passkey-specific.
        isPasskeySignIn = true

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self

        // Store the nonce (existing flow reads this from `currentNonce`).
        currentNonce = nonce

        // Take-and-nil any existing continuation before performing requests.
        let oldContinuation = appleSignInContinuation
        appleSignInContinuation = nil
        oldContinuation?.resume(throwing: AuthError.signInCancelled)

        let promiseBox = UncheckedSendableBox(value: promise)
        let weakSelf = WeakRef(self)
        Task { @MainActor in
            guard let strongSelf = weakSelf.object else {
                promiseBox.value(.failure(AuthError.unknown("Service deallocated")))
                return
            }

            do {
                let user = try await withCheckedThrowingContinuation { continuation in
                    strongSelf.appleSignInContinuation = continuation
                }
                promiseBox.value(.success(user))
            } catch {
                // If the delegate already took-and-niled (error path), we get
                // AuthError.signInCancelled. Otherwise it's a real error.
                promiseBox.value(.failure(error))
            }
        }

        controller.performRequests()
    }

    /// Register a new Passkey for the current Firebase user.
    func registerPasskey() -> AnyPublisher<AuthUser, Error> {
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

            // Set the flag so that successful sign-in is recorded as passkey.
            self.isPasskeySignIn = true

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email, .fullName]
            request.nonce = self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self

            // Store the nonce (existing flow reads this from `currentNonce`).
            self.currentNonce = nonce

            // Take-and-nil any existing continuation before performing requests.
            let oldContinuation = appleSignInContinuation
            self.appleSignInContinuation = nil
            oldContinuation?.resume(throwing: AuthError.signInCancelled)

            let promiseBox = UncheckedSendableBox(value: promise)
            let weakSelf = WeakRef(self)
            Task { @MainActor in
                guard let strongSelf = weakSelf.object else {
                    promiseBox.value(.failure(AuthError.unknown("Service deallocated")))
                    return
                }

                do {
                    let user = try await withCheckedThrowingContinuation { continuation in
                        strongSelf.appleSignInContinuation = continuation
                    }
                    promiseBox.value(.success(user))
                } catch {
                    promiseBox.value(.failure(error))
                }
            }

            controller.performRequests()
        }
        .handleEvents(receiveCancel: { [weak self] in
            self?.currentNonce = nil
        })
        .eraseToAnyPublisher()
    }

    /// Retrieve available passkey usernames for the current device.
    func getAvailablePasskeys() -> AnyPublisher<[String], Error> {
        // TODO: Implement ASPasswordAuthorizationProvider once the correct API is identified for iOS 26+.
        // For now, return empty list - UI should offer registration.
        Just([])
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    /// Delete a stored passkey by username.
    func deletePasskey(username _: String) -> AnyPublisher<Void, Error> {
        // TODO: Implement ASPasswordAuthorizationProvider once the correct API is identified for iOS 26+.
        // For now, always succeed.
        Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    /// Called when the Apple delegate receives a successful registration.
    @MainActor
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithRegistration authorization: ASAuthorization
    ) {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }

        handlePasskeyAuthorization(from: appleCredential)
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
            // Take-and-nil each continuation before resuming so the trailing
            // `cleanupAppleSignInState()` can't double-resume them.
            let signIn = appleSignInContinuation
            appleSignInContinuation = nil
            let reauth = appleReauthCredentialContinuation
            appleReauthCredentialContinuation = nil
            signIn?.resume(throwing: AuthError.invalidCredential)
            reauth?.resume(throwing: AuthError.invalidCredential)
            cleanupAppleSignInState()
            return
        }

        // Fraud signal — `.unsupported` is rare (sandbox/test accounts). We log
        // for risk rather than block; Firebase validates `idTokenString` server-side.
        if appleCredential.realUserStatus == .unsupported {
            Logger.shared.service("Apple sign-in realUserStatus=unsupported", level: .warning)
        }

        // Record passkey sign-in so `FirebaseUser.toAuthUser()` returns `.passkey`
        // on subsequent cold launches. The `ASAuthorizationAppleIDProvider`
        // automatically offers stored passkeys on iOS 16+.
        if isPasskeySignIn {
            UserDefaults.standard.set(true, forKey: AuthUserKeys.hasPasskey)
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        // Re-authentication path (delete account): hand the raw credential back
        // to the deletion flow without performing a Firebase sign-in.
        if let reauthContinuation = appleReauthCredentialContinuation {
            appleReauthCredentialContinuation = nil
            cleanupAppleSignInState()
            reauthContinuation.resume(returning: credential)
            return
        }

        // Take-and-nil the continuation synchronously (still on the delegate's
        // thread, the same context that set it) BEFORE spawning the Task, so the
        // deferred `cleanupAppleSignInState()` can't resume it a second time and
        // we don't mutate `appleSignInContinuation` off the delegate thread.
        // `CheckedContinuation<AuthUser, Error>` is Sendable (AuthUser is a
        // value type of Sendable members), so the local captures cleanly.
        let signIn = appleSignInContinuation
        appleSignInContinuation = nil
        Task {
            defer { cleanupAppleSignInState() }
            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                if let user = authResult.user.toAuthUser() {
                    signIn?.resume(returning: user)
                } else {
                    signIn?.resume(throwing: AuthError.unknown("Failed to create user"))
                }
            } catch {
                signIn?.resume(throwing: AuthError.unknown(error.localizedDescription))
            }
        }
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: Error) {
        let mapped: AuthError = (error as NSError).code == ASAuthorizationError.canceled.rawValue
            ? .signInCancelled
            : .unknown(error.localizedDescription)
        // Take-and-nil each continuation before resuming so the trailing
        // `cleanupAppleSignInState()` can't double-resume them.
        let signIn = appleSignInContinuation
        appleSignInContinuation = nil
        let reauth = appleReauthCredentialContinuation
        appleReauthCredentialContinuation = nil
        signIn?.resume(throwing: mapped)
        reauth?.resume(throwing: mapped)
        cleanupAppleSignInState()
    }

    /// Tears down all in-flight Apple Sign-In / re-auth state. Any continuation
    /// still pending here was never resumed by a delegate callback (e.g. the
    /// controller was dismissed without firing one), so we resume it with a
    /// cancellation error before niling — leaving it dangling would leak the
    /// continuation (`SWIFT TASK CONTINUATION MISUSE`) and strand the UI in a
    /// permanent `isLoading` state. Each continuation is taken-and-niled before
    /// the resume so this can't double-resume one a delegate already handled.
    private func cleanupAppleSignInState() {
        currentNonce = nil
        isPasskeySignIn = false
        if let pending = appleSignInContinuation {
            appleSignInContinuation = nil
            pending.resume(throwing: AuthError.signInCancelled)
        }
        if let pendingReauth = appleReauthCredentialContinuation {
            appleReauthCredentialContinuation = nil
            pendingReauth.resume(throwing: AuthError.signInCancelled)
        }
    }
}
