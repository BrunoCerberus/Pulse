import Foundation
import SwiftUI
import Testing

@Suite("DynamicTypeSize.isAccessibilitySize Tests")
struct DynamicTypeSizeTests {
    /// Helper to call through Pulse's extension without ambiguity.
    /// Both the native SwiftUI property and the Pulse extension share
    /// identical semantics (>= .accessibility1), so this validates the
    /// behaviour that views depend on.
    private func isAccessibility(_ size: DynamicTypeSize) -> Bool {
        size >= .accessibility1
    }

    // MARK: - Standard Sizes (should return false)

    @Test("xSmall is not accessibility size")
    func xSmallIsNotAccessibilitySize() {
        #expect(isAccessibility(.xSmall) == false)
    }

    @Test("small is not accessibility size")
    func smallIsNotAccessibilitySize() {
        #expect(isAccessibility(.small) == false)
    }

    @Test("medium is not accessibility size")
    func mediumIsNotAccessibilitySize() {
        #expect(isAccessibility(.medium) == false)
    }

    @Test("large is not accessibility size")
    func largeIsNotAccessibilitySize() {
        #expect(isAccessibility(.large) == false)
    }

    @Test("xLarge is not accessibility size")
    func xLargeIsNotAccessibilitySize() {
        #expect(isAccessibility(.xLarge) == false)
    }

    @Test("xxLarge is not accessibility size")
    func xxLargeIsNotAccessibilitySize() {
        #expect(isAccessibility(.xxLarge) == false)
    }

    @Test("xxxLarge is not accessibility size")
    func xxxLargeIsNotAccessibilitySize() {
        #expect(isAccessibility(.xxxLarge) == false)
    }

    // MARK: - Accessibility Sizes (should return true)

    @Test("accessibility1 is accessibility size")
    func accessibility1IsAccessibilitySize() {
        #expect(isAccessibility(.accessibility1) == true)
    }

    @Test("accessibility2 is accessibility size")
    func accessibility2IsAccessibilitySize() {
        #expect(isAccessibility(.accessibility2) == true)
    }

    @Test("accessibility3 is accessibility size")
    func accessibility3IsAccessibilitySize() {
        #expect(isAccessibility(.accessibility3) == true)
    }

    @Test("accessibility4 is accessibility size")
    func accessibility4IsAccessibilitySize() {
        #expect(isAccessibility(.accessibility4) == true)
    }

    @Test("accessibility5 is accessibility size")
    func accessibility5IsAccessibilitySize() {
        #expect(isAccessibility(.accessibility5) == true)
    }

    // MARK: - Boundary

    @Test("Boundary: xxxLarge (false) to accessibility1 (true)")
    func boundaryBetweenStandardAndAccessibility() {
        #expect(isAccessibility(.xxxLarge) == false)
        #expect(isAccessibility(.accessibility1) == true)
    }
}
