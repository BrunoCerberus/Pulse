import Foundation
@testable import Pulse
import StoreKit
import Testing

@Suite("PaywallDomainAction Tests")
struct PaywallDomainActionTests {
    @Test("loadProducts action exists")
    func loadProducts() {
        let action = PaywallDomainAction.loadProducts
        #expect(action == .loadProducts)
    }

    @Test("restorePurchases action exists")
    func restorePurchases() {
        let action = PaywallDomainAction.restorePurchases
        #expect(action == .restorePurchases)
    }

    @Test("dismiss action exists")
    func dismiss() {
        let action = PaywallDomainAction.dismiss
        #expect(action == .dismiss)
    }

    @Test("checkSubscriptionStatus action exists")
    func checkSubscriptionStatus() {
        let action = PaywallDomainAction.checkSubscriptionStatus
        #expect(action == .checkSubscriptionStatus)
    }

    @Test("Same actions are equal")
    func sameActionsAreEqual() {
        #expect(PaywallDomainAction.loadProducts == PaywallDomainAction.loadProducts)
        #expect(PaywallDomainAction.restorePurchases == PaywallDomainAction.restorePurchases)
        #expect(PaywallDomainAction.dismiss == PaywallDomainAction.dismiss)
        #expect(PaywallDomainAction.checkSubscriptionStatus == PaywallDomainAction.checkSubscriptionStatus)
    }

    @Test("Different actions are not equal")
    func differentActionsAreNotEqual() {
        #expect(PaywallDomainAction.loadProducts != PaywallDomainAction.restorePurchases)
        #expect(PaywallDomainAction.dismiss != PaywallDomainAction.checkSubscriptionStatus)
    }
}
