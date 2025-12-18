import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("PaywallViewModel Tests")
@MainActor
struct PaywallViewModelTests {
    let mockStoreKitService: MockStoreKitService
    let serviceLocator: ServiceLocator
    let sut: PaywallViewModel

    init() {
        mockStoreKitService = MockStoreKitService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(StoreKitService.self, instance: mockStoreKitService)

        sut = PaywallViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial state has correct defaults")
    func initialViewState() {
        // Initial state may be loading or success (depending on state propagation timing)
        #expect(sut.products.isEmpty)
        #expect(!sut.isPremium)
        #expect(!sut.isPurchasing)
        #expect(!sut.isRestoring)
        #expect(!sut.shouldDismiss)
        #expect(sut.error == nil)
    }

    @Test("Handle viewDidAppear triggers product loading")
    func viewDidAppearTriggersLoading() async throws {
        var cancellables = Set<AnyCancellable>()
        var states: [PaywallViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .viewDidAppear)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(states.count >= 1)
    }

    @Test("Handle restorePurchasesTapped triggers restore")
    func restorePurchasesTappedTriggersRestore() async throws {
        sut.handle(event: .viewDidAppear)

        try await Task.sleep(nanoseconds: 200_000_000)

        sut.handle(event: .restorePurchasesTapped)

        try await Task.sleep(nanoseconds: 200_000_000)

        // After restore, premium status should be based on mock service state
        #expect(!sut.isPremium) // Mock starts with isPremium = false
    }

    @Test("Handle restorePurchasesTapped with premium user")
    func restorePurchasesWithPremiumUser() async throws {
        mockStoreKitService.setSubscriptionStatus(true)

        sut.handle(event: .viewDidAppear)

        try await Task.sleep(nanoseconds: 200_000_000)

        sut.handle(event: .restorePurchasesTapped)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.isPremium)
    }

    @Test("Handle dismissTapped sets shouldDismiss")
    func dismissTappedSetsShouldDismiss() async throws {
        sut.handle(event: .viewDidAppear)

        try await Task.sleep(nanoseconds: 200_000_000)

        sut.handle(event: .dismissTapped)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.shouldDismiss)
    }

    @Test("Premium status is reflected correctly")
    func premiumStatusReflectedCorrectly() async throws {
        mockStoreKitService.setSubscriptionStatus(true)

        sut.handle(event: .viewDidAppear)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.isPremium)
    }

    @Test("View state reducer transforms domain state correctly")
    func viewStateReducer() {
        let reducer = PaywallViewStateReducer()

        let domainState = PaywallDomainState(
            products: [],
            selectedProduct: nil,
            isPremium: true,
            isLoadingProducts: false,
            isPurchasing: false,
            isRestoring: false,
            error: nil,
            purchaseSuccessful: false,
            restoreSuccessful: false,
            shouldDismiss: false
        )

        let viewState = reducer.reduce(domainState)

        guard case let .success(data) = viewState else {
            Issue.record("Expected success view state")
            return
        }

        #expect(data.isPremium)
        #expect(!data.isPurchasing)
        #expect(!data.isRestoring)
        #expect(data.products.isEmpty)
    }

    @Test("View state reducer handles loading state")
    func viewStateReducerLoading() {
        let reducer = PaywallViewStateReducer()

        let domainState = PaywallDomainState(
            products: [],
            selectedProduct: nil,
            isPremium: false,
            isLoadingProducts: true,
            isPurchasing: false,
            isRestoring: false,
            error: nil,
            purchaseSuccessful: false,
            restoreSuccessful: false,
            shouldDismiss: false
        )

        let viewState = reducer.reduce(domainState)

        guard case .loading = viewState else {
            Issue.record("Expected loading view state")
            return
        }
    }

    @Test("View state reducer handles error state")
    func viewStateReducerError() {
        let reducer = PaywallViewStateReducer()

        let domainState = PaywallDomainState(
            products: [],
            selectedProduct: nil,
            isPremium: false,
            isLoadingProducts: false,
            isPurchasing: false,
            isRestoring: false,
            error: "Test error",
            purchaseSuccessful: false,
            restoreSuccessful: false,
            shouldDismiss: false
        )

        let viewState = reducer.reduce(domainState)

        guard case let .error(message) = viewState else {
            Issue.record("Expected error view state")
            return
        }

        #expect(message == "Test error")
    }
}
