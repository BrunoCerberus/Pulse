import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("PaywallDomainInteractor Tests")
@MainActor
struct PaywallDomainInteractorTests {
    let mockStoreKitService: MockStoreKitService
    let serviceLocator: ServiceLocator
    let sut: PaywallDomainInteractor

    init() {
        mockStoreKitService = MockStoreKitService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(StoreKitService.self, instance: mockStoreKitService)

        sut = PaywallDomainInteractor(serviceLocator: serviceLocator)
    }

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.products.isEmpty)
        #expect(state.selectedProduct == nil)
        #expect(!state.isPremium)
        #expect(!state.isLoadingProducts)
        #expect(!state.isPurchasing)
        #expect(!state.isRestoring)
        #expect(state.error == nil)
        #expect(!state.purchaseSuccessful)
        #expect(!state.restoreSuccessful)
        #expect(!state.shouldDismiss)
    }

    @Test("Load products action sets loading state")
    func loadProductsSetsLoadingState() async throws {
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.statePublisher
            .map(\.isLoadingProducts)
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .loadProducts)

        try await Task.sleep(nanoseconds: 200_000_000)

        // Should have at least loading = true then loading = false
        #expect(loadingStates.contains(true))
    }

    @Test("Restore purchases action sets restoring state")
    func restorePurchasesSetsRestoringState() async throws {
        var cancellables = Set<AnyCancellable>()
        var restoringStates: [Bool] = []

        sut.statePublisher
            .map(\.isRestoring)
            .sink { isRestoring in
                restoringStates.append(isRestoring)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .restorePurchases)

        try await Task.sleep(nanoseconds: 200_000_000)

        // Should have at least one restoring = true state
        #expect(restoringStates.contains(true))
    }

    @Test("Dismiss action sets shouldDismiss")
    func dismissAction() async throws {
        sut.dispatch(action: .dismiss)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.shouldDismiss)
    }

    @Test("Subscription status is observed from service")
    func subscriptionStatusObserved() async throws {
        mockStoreKitService.setSubscriptionStatus(true)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.currentState.isPremium)
    }

    @Test("Restore with premium status sets isPremium")
    func restoreWithPremiumStatus() async throws {
        mockStoreKitService.setSubscriptionStatus(true)

        sut.dispatch(action: .restorePurchases)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.currentState.isPremium)
        #expect(sut.currentState.restoreSuccessful)
    }

    @Test("Check subscription status action updates premium status")
    func checkSubscriptionStatusAction() async throws {
        mockStoreKitService.setSubscriptionStatus(true)

        sut.dispatch(action: .checkSubscriptionStatus)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.currentState.isPremium)
    }

    @Test("Domain state copy helper works correctly")
    func domainStateCopy() {
        let initial = PaywallDomainState.initial

        let modified = initial.copy(isPremium: true, isLoadingProducts: true)

        #expect(modified.isPremium)
        #expect(modified.isLoadingProducts)
        #expect(modified.products.isEmpty) // Unchanged
        #expect(!modified.isPurchasing) // Unchanged
    }
}
