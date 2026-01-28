import Foundation
@testable import Pulse
import StoreKit
import Testing

@Suite("PaywallDomainState Tests")
struct PaywallDomainStateTests {
    @Test("Initial state has correct default values")
    func initialState() {
        let state = PaywallDomainState.initial

        #expect(state.products.isEmpty)
        #expect(state.selectedProduct == nil)
        #expect(state.isPremium == false)
        #expect(state.isLoadingProducts == false)
        #expect(state.isPurchasing == false)
        #expect(state.isRestoring == false)
        #expect(state.error == nil)
        #expect(state.purchaseSuccessful == false)
        #expect(state.restoreSuccessful == false)
        #expect(state.shouldDismiss == false)
    }

    @Test("State properties can be mutated")
    func statePropertiesMutability() {
        var state = PaywallDomainState.initial

        state.isPremium = true
        #expect(state.isPremium == true)

        state.isLoadingProducts = true
        #expect(state.isLoadingProducts == true)

        state.isPurchasing = true
        #expect(state.isPurchasing == true)

        state.isRestoring = true
        #expect(state.isRestoring == true)

        state.error = "Payment failed"
        #expect(state.error == "Payment failed")

        state.purchaseSuccessful = true
        #expect(state.purchaseSuccessful == true)

        state.restoreSuccessful = true
        #expect(state.restoreSuccessful == true)

        state.shouldDismiss = true
        #expect(state.shouldDismiss == true)
    }

    @Test("Copy method creates state with same values")
    func copyMethod() {
        let original = PaywallDomainState.initial
        let copy = original.copy()

        #expect(copy.isPremium == original.isPremium)
        #expect(copy.isLoadingProducts == original.isLoadingProducts)
        #expect(copy.error == original.error)
    }

    @Test("Copy method with overrides")
    func copyWithOverrides() {
        let original = PaywallDomainState.initial
        let copy = original.copy(
            isPremium: true,
            isPurchasing: true,
            error: "Test error"
        )

        #expect(copy.isPremium == true)
        #expect(copy.isPurchasing == true)
        #expect(copy.error == "Test error")
        #expect(copy.isLoadingProducts == original.isLoadingProducts)
    }

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        let state1 = PaywallDomainState.initial
        let state2 = PaywallDomainState.initial

        #expect(state1 == state2)
    }

    @Test("States with different isPremium are not equal")
    func differentIsPremium() {
        let state1 = PaywallDomainState.initial
        var state2 = PaywallDomainState.initial
        state2.isPremium = true

        #expect(state1 != state2)
    }

    @Test("States with different isPurchasing are not equal")
    func differentIsPurchasing() {
        let state1 = PaywallDomainState.initial
        var state2 = PaywallDomainState.initial
        state2.isPurchasing = true

        #expect(state1 != state2)
    }

    @Test("States with different error are not equal")
    func differentError() {
        let state1 = PaywallDomainState.initial
        var state2 = PaywallDomainState.initial
        state2.error = "Error"

        #expect(state1 != state2)
    }
}
