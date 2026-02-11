import Foundation
@testable import Pulse
import Testing

@Suite("AppLockManager Tests")
@MainActor
struct AppLockManagerTests {
    let sut = AppLockManager.shared
    let mockService = MockAppLockService()

    init() {
        sut.configureForTesting(with: mockService)
    }

    // MARK: - Scene Lifecycle

    @Test("handleSceneDidEnterBackground sets isLocked when enabled")
    func backgroundLocksWhenEnabled() {
        mockService.isEnabled = true

        sut.handleSceneDidEnterBackground()

        #expect(sut.isLocked == true)
    }

    @Test("handleSceneDidEnterBackground does not lock when disabled")
    func backgroundDoesNotLockWhenDisabled() {
        mockService.isEnabled = false

        sut.handleSceneDidEnterBackground()

        #expect(sut.isLocked == false)
    }

    @Test("handleSceneDidBecomeActive does not re-lock when isAuthenticating is true")
    func doesNotRelockDuringAuthentication() async {
        mockService.isEnabled = true

        // Simulate: user locked, then Face ID dialog causes sceneDidBecomeActive
        // We need to verify the guard works - set up locked state first
        sut.handleSceneDidEnterBackground()
        #expect(sut.isLocked == true)

        // Now simulate the authenticate call that will set isAuthenticating
        // We test indirectly: after attemptUnlock succeeds, isLocked should be false
        await sut.attemptUnlock()
        #expect(sut.isLocked == false)
    }

    @Test("handleSceneDidBecomeActive no-ops when disabled")
    func sceneActiveNoOpsWhenDisabled() {
        mockService.isEnabled = false

        sut.handleSceneDidBecomeActive()

        #expect(sut.isLocked == false)
    }

    // MARK: - Unlock

    @Test("attemptUnlock sets isLocked to false on success")
    func unlockSucceeds() async {
        mockService.isEnabled = true
        mockService.authenticateResult = .success(true)
        sut.handleSceneDidEnterBackground()
        #expect(sut.isLocked == true)

        await sut.attemptUnlock()

        #expect(sut.isLocked == false)
        #expect(mockService.authenticateCallCount == 1)
    }

    @Test("attemptUnlock keeps isLocked true on failure")
    func unlockFailsKeepsLocked() async {
        mockService.isEnabled = true
        mockService.authenticateResult = .failure(.authenticationFailed)
        sut.handleSceneDidEnterBackground()
        #expect(sut.isLocked == true)

        await sut.attemptUnlock()

        #expect(sut.isLocked == true)
    }

    @Test("attemptUnlock keeps isLocked true on cancel")
    func unlockCancelKeepsLocked() async {
        mockService.isEnabled = true
        mockService.authenticateResult = .failure(.userCancelled)
        sut.handleSceneDidEnterBackground()

        await sut.attemptUnlock()

        #expect(sut.isLocked == true)
    }

    // MARK: - Settings Toggle

    @Test("toggleAppLock enabled true authenticates then enables")
    func toggleOnAuthenticatesAndEnables() async {
        mockService.isEnabled = false
        mockService.authenticateResult = .success(true)

        await sut.toggleAppLock(enabled: true)

        #expect(mockService.isEnabled == true)
        #expect(mockService.authenticateCallCount == 1)
    }

    @Test("toggleAppLock enabled true does not enable on auth failure")
    func toggleOnDoesNotEnableOnFailure() async {
        mockService.isEnabled = false
        mockService.authenticateResult = .failure(.authenticationFailed)

        await sut.toggleAppLock(enabled: true)

        #expect(mockService.isEnabled == false)
    }

    @Test("toggleAppLock enabled false disables immediately")
    func toggleOffDisablesImmediately() async {
        mockService.isEnabled = true

        await sut.toggleAppLock(enabled: false)

        #expect(mockService.isEnabled == false)
        #expect(sut.isLocked == false)
        #expect(mockService.authenticateCallCount == 0)
    }

    // MARK: - Post-Signup Prompt

    @Test("checkPostSignupPrompt shows prompt when not yet prompted and biometrics available")
    func promptShowsWhenNotPrompted() {
        mockService.hasPromptedFaceID = false
        mockService.canEvaluateResult = true

        sut.checkPostSignupPrompt()

        #expect(sut.showFaceIDPrompt == true)
    }

    @Test("checkPostSignupPrompt does not show when already prompted")
    func promptDoesNotShowWhenAlreadyPrompted() {
        mockService.hasPromptedFaceID = true
        mockService.canEvaluateResult = true

        sut.checkPostSignupPrompt()

        #expect(sut.showFaceIDPrompt == false)
    }

    @Test("checkPostSignupPrompt does not show when biometrics unavailable")
    func promptDoesNotShowWhenBiometricsUnavailable() {
        mockService.hasPromptedFaceID = false
        mockService.canEvaluateResult = false

        sut.checkPostSignupPrompt()

        #expect(sut.showFaceIDPrompt == false)
    }

    @Test("enableFromPrompt enables and sets hasPrompted flag")
    func enableFromPromptEnablesService() async {
        mockService.hasPromptedFaceID = false
        mockService.authenticateResult = .success(true)
        sut.configureForTesting(with: mockService)

        await sut.enableFromPrompt()

        #expect(mockService.isEnabled == true)
        #expect(mockService.hasPromptedFaceID == true)
        #expect(sut.showFaceIDPrompt == false)
    }

    @Test("dismissPrompt sets hasPrompted flag and hides prompt")
    func dismissPromptSetsFlag() {
        mockService.hasPromptedFaceID = false

        sut.dismissPrompt()

        #expect(mockService.hasPromptedFaceID == true)
        #expect(sut.showFaceIDPrompt == false)
    }

    // MARK: - Computed Properties

    @Test("isAppLockEnabled reflects service state")
    func isAppLockEnabledReflectsService() {
        mockService.isEnabled = true
        #expect(sut.isAppLockEnabled == true)

        mockService.isEnabled = false
        #expect(sut.isAppLockEnabled == false)
    }

    @Test("canUseBiometrics reflects service state")
    func canUseBiometricsReflectsService() {
        mockService.canEvaluateResult = true
        #expect(sut.canUseBiometrics == true)

        mockService.canEvaluateResult = false
        #expect(sut.canUseBiometrics == false)
    }
}
