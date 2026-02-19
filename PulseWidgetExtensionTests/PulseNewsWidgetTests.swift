import SwiftUI
import Testing
import WidgetKit

@Suite("PulseNewsWidget Tests")
struct PulseNewsWidgetTests {
    @Test("widget has correct kind")
    func widgetHasCorrectKind() {
        let widget = PulseNewsWidget()
        #expect(widget.kind == "PulseNewsWidget")
    }
}
