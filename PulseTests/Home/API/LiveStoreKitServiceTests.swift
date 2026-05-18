import Combine
import EntropyCore
import Foundation
@testable import Pulse
import StoreKit
import Testing

@Suite("LiveStoreKitService Tests")
struct LiveStoreKitServiceTests {
    @Test("LiveStoreKitService can be instantiated")
    func canBeInstantiated() {
        let service = LiveStoreKitService(startListening: false)
        let _: any StoreKitService = service
    }

    @Test("isPremium returns false initially")
    func isPremiumReturnsFalseInitially() {
        let service = LiveStoreKitService(startListening: false)
        #expect(service.isPremium == false)
    }

    @Test("subscriptionStatusPublisher returns correct publisher type")
    func subscriptionStatusPublisherReturnsCorrectType() {
        let service = LiveStoreKitService(startListening: false)
        let publisher = service.subscriptionStatusPublisher
        let _: AnyPublisher<Bool, Never> = publisher
    }

    @Test("fetchProducts returns correct publisher type")
    func fetchProductsReturnsCorrectType() {
        let service = LiveStoreKitService(startListening: false)
        let publisher = service.fetchProducts()
        let _: AnyPublisher<[Product], Error> = publisher
    }

    @Test("restorePurchases returns correct publisher type")
    func restorePurchasesReturnsCorrectType() {
        let service = LiveStoreKitService(startListening: false)
        let publisher = service.restorePurchases()
        let _: AnyPublisher<Bool, Error> = publisher
    }

    @Test("checkSubscriptionStatus returns correct publisher type")
    func checkSubscriptionStatusReturnsCorrectType() {
        let service = LiveStoreKitService(startListening: false)
        let publisher = service.checkSubscriptionStatus()
        let _: AnyPublisher<Bool, Never> = publisher
    }

    @Test("refreshSubscriptionStatus returns Bool from StoreKit 2 entitlements")
    func refreshReturnsBool() async {
        let service = LiveStoreKitService(startListening: false)
        // With no live entitlements in the test environment, the call should
        // complete and report `false`. The point is that it goes through
        // `Transaction.currentEntitlements` rather than the cached value, so
        // a tamper of `isPremium` wouldn't help here.
        let result = await service.refreshSubscriptionStatus()
        #expect(result == false)
    }

    @Test("MockStoreKitService.refreshSubscriptionStatus reflects configured state")
    func mockRefreshReflectsState() async {
        let mockFree = MockStoreKitService(isPremium: false)
        #expect(await mockFree.refreshSubscriptionStatus() == false)

        let mockPremium = MockStoreKitService(isPremium: true)
        #expect(await mockPremium.refreshSubscriptionStatus() == true)
    }
}
