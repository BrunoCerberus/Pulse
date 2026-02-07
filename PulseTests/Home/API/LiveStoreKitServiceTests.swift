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
        #expect(service is StoreKitService)
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
        let typeCheck: AnyPublisher<Bool, Never> = publisher
        #expect(typeCheck is AnyPublisher<Bool, Never>)
    }

    @Test("fetchProducts returns correct publisher type")
    func fetchProductsReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.fetchProducts()
        let typeCheck: AnyPublisher<[Product], Error> = publisher
        #expect(typeCheck is AnyPublisher<[Product], Error>)
    }

    @Test("purchase returns correct publisher type")
    func purchaseReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.purchase(Product.mock)
        let typeCheck: AnyPublisher<Bool, Error> = publisher
        #expect(typeCheck is AnyPublisher<Bool, Error>)
    }

    @Test("restorePurchases returns correct publisher type")
    func restorePurchasesReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.restorePurchases()
        let typeCheck: AnyPublisher<Bool, Error> = publisher
        #expect(typeCheck is AnyPublisher<Bool, Error>)
    }

    @Test("checkSubscriptionStatus returns correct publisher type")
    func checkSubscriptionStatusReturnsCorrectType() {
        let service = LiveStoreKitService()
        let publisher = service.checkSubscriptionStatus()
        let typeCheck: AnyPublisher<Bool, Never> = publisher
        #expect(typeCheck is AnyPublisher<Bool, Never>)
    }
}

extension Product {
    static var mock: Product {
        Product(
            id: "com.bruno.Pulse.premium.monthly",
            displayPrice: "$4.99",
            price: 4.99,
            currencyCode: "USD",
            subscription: nil
        )
    }
}
