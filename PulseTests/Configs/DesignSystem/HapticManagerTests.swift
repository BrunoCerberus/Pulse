import Foundation
@testable import Pulse
import Testing

@Suite("HapticManager Tests")
@MainActor
struct HapticManagerTests {
    let sut = HapticManager.shared

    // MARK: - Singleton Tests

    @Test("Shared instance is accessible")
    func sharedInstanceIsAccessible() {
        #expect(HapticManager.shared === sut)
    }

    // MARK: - Impact Feedback Tests

    @Test("Light impact feedback executes")
    func lightImpactFeedbackExecutes() {
        sut.impact(.light)
    }

    @Test("Medium impact feedback executes")
    func mediumImpactFeedbackExecutes() {
        sut.impact(.medium)
    }

    @Test("Heavy impact feedback executes")
    func heavyImpactFeedbackExecutes() {
        sut.impact(.heavy)
    }

    @Test("Soft impact feedback executes")
    func softImpactFeedbackExecutes() {
        sut.impact(.soft)
    }

    @Test("Rigid impact feedback executes")
    func rigidImpactFeedbackExecutes() {
        sut.impact(.rigid)
    }

    // MARK: - Impact with Intensity Tests

    @Test("Impact with zero intensity executes")
    func impactWithZeroIntensityExecutes() {
        sut.impact(.medium, intensity: 0.0)
    }

    @Test("Impact with full intensity executes")
    func impactWithFullIntensityExecutes() {
        sut.impact(.medium, intensity: 1.0)
    }

    @Test("Impact with half intensity executes")
    func impactWithHalfIntensityExecutes() {
        sut.impact(.soft, intensity: 0.5)
    }

    // MARK: - Selection Feedback Tests

    @Test("Selection changed feedback executes")
    func selectionChangedFeedbackExecutes() {
        sut.selectionChanged()
    }

    // MARK: - Notification Feedback Tests

    @Test("Success notification feedback executes")
    func successNotificationFeedbackExecutes() {
        sut.notification(.success)
    }

    @Test("Warning notification feedback executes")
    func warningNotificationFeedbackExecutes() {
        sut.notification(.warning)
    }

    @Test("Error notification feedback executes")
    func errorNotificationFeedbackExecutes() {
        sut.notification(.error)
    }

    // MARK: - Convenience Method Tests

    @Test("Tap convenience method executes")
    func tapConvenienceMethodExecutes() {
        sut.tap()
    }

    @Test("Button press convenience method executes")
    func buttonPressConvenienceMethodExecutes() {
        sut.buttonPress()
    }

    @Test("Success convenience method executes")
    func successConvenienceMethodExecutes() {
        sut.success()
    }

    @Test("Warning convenience method executes")
    func warningConvenienceMethodExecutes() {
        sut.warning()
    }

    @Test("Error convenience method executes")
    func errorConvenienceMethodExecutes() {
        sut.error()
    }

    @Test("Tab change convenience method executes")
    func tabChangeConvenienceMethodExecutes() {
        sut.tabChange()
    }

    @Test("Card press convenience method executes")
    func cardPressConvenienceMethodExecutes() {
        sut.cardPress()
    }

    @Test("Refresh convenience method executes")
    func refreshConvenienceMethodExecutes() {
        sut.refresh()
    }
}
