import SwiftUI

extension DynamicTypeSize {
    /// Returns `true` when the user has selected an accessibility text size (.accessibility1 or larger).
    var isAccessibilitySize: Bool {
        self >= .accessibility1
    }
}
