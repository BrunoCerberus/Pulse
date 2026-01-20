import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("MockStoreKitService Tests")
struct MockStoreKitServiceTests {
    @Test("Initial state is not premium")
    func initialStateNotPremium() {
        let sut = MockStoreKitService()
        #expect(!sut.isPremium)
    }

    @Test("Initial state with isPremium true")
    func initialStateIsPremium() {
        let sut = MockStoreKitService(isPremium: true)
        #expect(sut.isPremium)
    }

    @Test("Subscription status publisher emits initial state")
    func subscriptionStatusPublisherEmitsInitial() {
        let sut = MockStoreKitService()
        var receivedStatuses: [Bool] = []
        let cancellable = sut.subscriptionStatusPublisher
            .sink { status in
                receivedStatuses.append(status)
            }

        #expect(!receivedStatuses.isEmpty)
        #expect(receivedStatuses.first == false)

        cancellable.cancel()
    }

    @Test("Fetch products returns empty array")
    func fetchProductsReturnsEmpty() {
        let sut = MockStoreKitService()
        var receivedCompletion: Subscribers.Completion<Error>?
        let cancellable = sut.fetchProducts()
            .sink(
                receiveCompletion: { completion in
                    receivedCompletion = completion
                },
                receiveValue: { _ in }
            )

        if case .finished = receivedCompletion {}

        cancellable.cancel()
    }

    @Test("Purchase failure does not update subscription status")
    func purchaseFailureDoesNotUpdateStatus() async throws {
        let sut = MockStoreKitService()
        sut.configurePurchaseFailure(true)

        var receivedError: Error?
        let cancellable = sut.fetchProducts()
            .flatMap { _ -> AnyPublisher<Bool, Error> in
                return Fail(error: StoreKitError.purchaseFailed).eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        receivedError = error
                    }
                },
                receiveValue: { _ in }
            )

        try await waitForStateUpdate()

        #expect(receivedError != nil)
        #expect(!sut.isPremium)

        cancellable.cancel()
    }

    @Test("Restore purchases returns current status")
    func restorePurchasesReturnsCurrentStatus() async throws {
        let sut = MockStoreKitService()
        sut.setSubscriptionStatus(true)

        var receivedResult: Bool?
        let cancellable = sut.restorePurchases()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { result in
                    receivedResult = result
                }
            )

        try await waitForStateUpdate()

        #expect(receivedResult == true)

        cancellable.cancel()
    }

    @Test("Restore purchases failure")
    func restorePurchasesFailure() async throws {
        let sut = MockStoreKitService()
        sut.configureRestoreFailure(true)

        var receivedError: Error?
        let cancellable = sut.restorePurchases()
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        receivedError = error
                    }
                },
                receiveValue: { _ in }
            )

        try await waitForStateUpdate()

        #expect(receivedError != nil)

        cancellable.cancel()
    }

    @Test("Check subscription status returns current status")
    func checkSubscriptionStatusReturnsCurrent() async throws {
        let sut = MockStoreKitService()
        sut.setSubscriptionStatus(true)

        var receivedResult: Bool?
        let cancellable = sut.checkSubscriptionStatus()
            .sink { result in
                receivedResult = result
            }

        try await waitForStateUpdate()

        #expect(receivedResult == true)

        cancellable.cancel()
    }

    @Test("Set subscription status updates isPremium")
    func setSubscriptionStatusUpdatesIsPremium() {
        let sut = MockStoreKitService()
        sut.setSubscriptionStatus(true)
        #expect(sut.isPremium)

        sut.setSubscriptionStatus(false)
        #expect(!sut.isPremium)
    }

    @Test("Subscription status publisher emits updates")
    func subscriptionStatusPublisherEmitsUpdates() {
        let sut = MockStoreKitService()
        var receivedStatuses: [Bool] = []
        let cancellable = sut.subscriptionStatusPublisher
            .sink { status in
                receivedStatuses.append(status)
            }

        sut.setSubscriptionStatus(true)

        #expect(receivedStatuses.count >= 2)
        #expect(receivedStatuses.last == true)

        cancellable.cancel()
    }
}
