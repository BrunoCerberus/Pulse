import Foundation
@testable import Pulse
import Testing

@Suite("PaywallDomainEventActionMap Tests")
struct PaywallDomainEventActionMapTests {
    @Test("viewDidAppear maps to loadProducts")
    func viewDidAppearMapsToLoadProducts() {
        let action = PaywallDomainEventActionMap.map(.viewDidAppear)

        #expect(action == .loadProducts)
    }

    @Test("restorePurchasesTapped maps to restorePurchases")
    func restorePurchasesTappedMapsToRestorePurchases() {
        let action = PaywallDomainEventActionMap.map(.restorePurchasesTapped)

        #expect(action == .restorePurchases)
    }

    @Test("dismissTapped maps to dismiss")
    func dismissTappedMapsToDismiss() {
        let action = PaywallDomainEventActionMap.map(.dismissTapped)

        #expect(action == .dismiss)
    }
}
