import Foundation
@testable import Pulse
import StoreKit
import Testing

@Suite("PendingPurchaseStore Tests")
struct PendingPurchaseStoreTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private var future: Date {
        now.addingTimeInterval(3600)
    }

    private var past: Date {
        now.addingTimeInterval(-3600)
    }

    // MARK: - No recorded purchase

    @Test("An empty scan with nothing recorded stays non-premium")
    func emptyScanWithoutPendingPurchase() {
        let store = PendingPurchaseStore()

        #expect(store.resolve(scanFoundActiveSubscription: false, now: now) == false)
    }

    @Test("A scan that finds the subscription is premium")
    func scanFindingSubscription() {
        let store = PendingPurchaseStore()

        #expect(store.resolve(scanFoundActiveSubscription: true, now: now) == true)
    }

    // MARK: - The lag this store exists for

    @Test("A just-verified purchase is premium while the entitlement scan lags")
    func pendingPurchaseCoversLaggingScan() {
        let store = PendingPurchaseStore()
        store.record(productType: .autoRenewable, revocationDate: nil, expirationDate: future)

        #expect(store.resolve(scanFoundActiveSubscription: false, now: now) == true)
    }

    @Test("A purchase with no expiry date is premium while the scan lags")
    func pendingPurchaseWithoutExpiryCoversLaggingScan() {
        let store = PendingPurchaseStore()
        store.record(productType: .autoRenewable, revocationDate: nil, expirationDate: nil)

        #expect(store.resolve(scanFoundActiveSubscription: false, now: now) == true)
    }

    @Test("The pending purchase is dropped once the scan catches up")
    func pendingPurchaseClearedWhenScanCatchesUp() {
        let store = PendingPurchaseStore()
        store.record(productType: .autoRenewable, revocationDate: nil, expirationDate: future)

        #expect(store.resolve(scanFoundActiveSubscription: true, now: now) == true)
        // Entitlement later disappears (cancelled/refunded) — nothing left to vouch for it.
        #expect(store.resolve(scanFoundActiveSubscription: false, now: now) == false)
    }

    // MARK: - The store must not mask a real loss of entitlement

    @Test("An expired purchase stops vouching for premium")
    func expiredPendingPurchaseIsNotPremium() {
        let store = PendingPurchaseStore()
        store.record(productType: .autoRenewable, revocationDate: nil, expirationDate: past)

        #expect(store.resolve(scanFoundActiveSubscription: false, now: now) == false)
    }

    @Test("A purchase stops vouching for premium once it expires")
    func pendingPurchaseExpiresOverTime() {
        let store = PendingPurchaseStore()
        store.record(productType: .autoRenewable, revocationDate: nil, expirationDate: future)

        #expect(store.resolve(scanFoundActiveSubscription: false, now: now) == true)
        #expect(store.resolve(scanFoundActiveSubscription: false, now: future.addingTimeInterval(1)) == false)
    }

    @Test("A revoked transaction is never recorded")
    func revokedTransactionIsNotRecorded() {
        let store = PendingPurchaseStore()
        store.record(productType: .autoRenewable, revocationDate: past, expirationDate: future)

        #expect(store.resolve(scanFoundActiveSubscription: false, now: now) == false)
    }

    @Test("A refund after the purchase was recorded drops the recorded purchase")
    func revocationAfterRecordingClearsPendingPurchase() {
        let store = PendingPurchaseStore()
        store.record(productType: .autoRenewable, revocationDate: nil, expirationDate: future)
        #expect(store.resolve(scanFoundActiveSubscription: false, now: now) == true)

        // The refund arrives via `Transaction.updates` as the same transaction, now revoked, and
        // is already absent from the entitlement scan — this is the only chance to drop it.
        store.record(productType: .autoRenewable, revocationDate: now, expirationDate: future)

        #expect(store.resolve(scanFoundActiveSubscription: false, now: now) == false)
    }

    @Test("A non-subscription product is never recorded", arguments: [
        Product.ProductType.consumable,
        .nonConsumable,
        .nonRenewable,
    ])
    func nonSubscriptionProductIsNotRecorded(productType: Product.ProductType) {
        let store = PendingPurchaseStore()
        store.record(productType: productType, revocationDate: nil, expirationDate: future)

        #expect(store.resolve(scanFoundActiveSubscription: false, now: now) == false)
    }
}
