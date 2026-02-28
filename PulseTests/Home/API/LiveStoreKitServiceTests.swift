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
        let service = LiveStoreKitService()
        let _: any StoreKitService = service
    }

    @Test("isPremium returns false initially")
    func isPremiumReturnsFalseInitially() {
        let service = LiveStoreKitService()
        #expect(service.isPremium == false)
    }

    @Test("subscriptionStatusPublisher returns correct publisher type")
    func subscriptionStatusPublisherReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.subscriptionStatusPublisher
        let _: AnyPublisher<Bool, Never> = publisher
    }

    @Test("fetchProducts returns correct publisher type")
    func fetchProductsReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.fetchProducts()
        let _: AnyPublisher<[Product], Error> = publisher
    }

    @Test("restorePurchases returns correct publisher type")
    func restorePurchasesReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.restorePurchases()
        let _: AnyPublisher<Bool, Error> = publisher
    }

    @Test("checkSubscriptionStatus returns correct publisher type")
    func checkSubscriptionStatusReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.checkSubscriptionStatus()
        let _: AnyPublisher<Bool, Never> = publisher
    }
}
