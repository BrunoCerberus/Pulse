import Foundation
@testable import Pulse
import Testing

@Suite("PaywallViewState Tests")
struct PaywallViewStateTests {
    @Test("Loading state is Equatable")
    func loadingEquatable() {
        #expect(PaywallViewState.loading == PaywallViewState.loading)
    }

    @Test("Error state is Equatable")
    func errorEquatable() {
        let error1 = PaywallViewState.error("Something went wrong")
        let error2 = PaywallViewState.error("Something went wrong")
        let error3 = PaywallViewState.error("Different error")

        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    @Test("Different states are not equal")
    func differentStatesNotEqual() {
        let loading = PaywallViewState.loading
        let error = PaywallViewState.error("Error")

        #expect(loading != error)
    }
}
