import SwiftUI
import UIKit
import WidgetKit
@testable import PulseWidgetExtension
import Testing

@Suite("PulseNewsWidget Tests")
struct PulseNewsWidgetTests {
    @Test("widget has correct kind")
    func widgetHasCorrectKind() {
        let widget = PulseNewsWidget()
        #expect(widget.kind == "PulseNewsWidget")
    }

    @Test("widget has correct configuration display name")
    func widgetHasCorrectDisplayName() {
        let widget = PulseNewsWidget()
        #expect(widget.body.configuration.displayName == "Top Headlines")
    }

    @Test("widget has correct description")
    func widgetHasCorrectDescription() {
        let widget = PulseNewsWidget()
        #expect(widget.body.configuration.description == "Stay updated with the latest news headlines.")
    }

    @Test("widget supports correct families")
    func widgetSupportsCorrectFamilies() {
        let widget = PulseNewsWidget()
        #expect(widget.body.configuration.supportedFamilies.contains(.systemSmall))
        #expect(widget.body.configuration.supportedFamilies.contains(.systemMedium))
        #expect(widget.body.configuration.supportedFamilies.contains(.systemLarge))
    }
}
