import Combine
import EntropyCore
import Foundation
@testable import Pulse
import SwiftUI
import Testing

@Suite("RootView Tests")
@MainActor
struct RootViewTests {
    @Test("RootView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let view = RootView(serviceLocator: serviceLocator)
        #expect(view.serviceLocator === serviceLocator)
    }

    @Test("init sets serviceLocator")
    func initSetsServiceLocator() {
        let serviceLocator = ServiceLocator()
        let view = RootView(serviceLocator: serviceLocator)
        #expect(view.serviceLocator === serviceLocator)
    }

    // MARK: - shouldShowPrivacyOverlay

    private let stubUser = AuthUser(
        uid: "uid-1",
        email: "test@example.com",
        displayName: nil,
        photoURL: nil,
        provider: .google,
    )

    @Test("Privacy overlay hidden when App Lock is disabled")
    func privacyOverlayHiddenWhenAppLockDisabled() {
        let result = RootView.shouldShowPrivacyOverlay(
            authState: .authenticated(stubUser),
            scenePhase: .background,
            isAppLockEnabled: false,
            isAuthenticating: false,
        )
        #expect(result == false)
    }

    @Test("Privacy overlay hidden when user is unauthenticated")
    func privacyOverlayHiddenWhenUnauthenticated() {
        let result = RootView.shouldShowPrivacyOverlay(
            authState: .unauthenticated,
            scenePhase: .background,
            isAppLockEnabled: true,
            isAuthenticating: false,
        )
        #expect(result == false)
    }

    @Test("Privacy overlay hidden when scene is active")
    func privacyOverlayHiddenWhenSceneActive() {
        let result = RootView.shouldShowPrivacyOverlay(
            authState: .authenticated(stubUser),
            scenePhase: .active,
            isAppLockEnabled: true,
            isAuthenticating: false,
        )
        #expect(result == false)
    }

    @Test("Privacy overlay hidden during biometry prompt")
    func privacyOverlayHiddenDuringBiometry() {
        let result = RootView.shouldShowPrivacyOverlay(
            authState: .authenticated(stubUser),
            scenePhase: .inactive,
            isAppLockEnabled: true,
            isAuthenticating: true,
        )
        #expect(result == false)
    }

    @Test("Privacy overlay shown for inactive phase when opted in")
    func privacyOverlayShownInactive() {
        let result = RootView.shouldShowPrivacyOverlay(
            authState: .authenticated(stubUser),
            scenePhase: .inactive,
            isAppLockEnabled: true,
            isAuthenticating: false,
        )
        #expect(result == true)
    }

    @Test("Privacy overlay shown for background phase when opted in")
    func privacyOverlayShownBackground() {
        let result = RootView.shouldShowPrivacyOverlay(
            authState: .authenticated(stubUser),
            scenePhase: .background,
            isAppLockEnabled: true,
            isAuthenticating: false,
        )
        #expect(result == true)
    }

    @Test("Privacy overlay hidden during loading auth state")
    func privacyOverlayHiddenDuringLoading() {
        let result = RootView.shouldShowPrivacyOverlay(
            authState: .loading,
            scenePhase: .background,
            isAppLockEnabled: true,
            isAuthenticating: false,
        )
        #expect(result == false)
    }
}
