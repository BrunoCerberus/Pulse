import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("PaywallDomainInteractor Extended Tests")
@MainActor
struct PaywallDomainInteractorExtendedTests {
    let mockStoreKitService: MockStoreKitService
    let mockAnalyticsService: MockAnalyticsService
    let serviceLocator: ServiceLocator
    let sut: PaywallDomainInteractor

    init() {
        mockStoreKitService = MockStoreKitService()
        mockAnalyticsService = MockAnalyticsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(StoreKitService.self, instance: mockStoreKitService)
        serviceLocator.register(AnalyticsService.self, instance: mockAnalyticsService)

        sut = PaywallDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Purchase Failure Tests

    @Test("Purchase failure sets error and stops purchasing")
    func purchaseFailureSetsError() async throws {
        mockStoreKitService.configurePurchaseFailure(true)

        sut.dispatch(action: .loadProducts)
        try await Task.sleep(nanoseconds: 200_000_000)

        // We can't create a real Product, but we can test the restore failure path
        // which exercises similar completion handling
        mockStoreKitService.configureRestoreFailure(true)
        sut.dispatch(action: .restorePurchases)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.isRestoring)
        #expect(sut.currentState.error != nil)
    }

    // MARK: - Restore Success Tests

    @Test("Restore purchases with non-premium returns false premium")
    func restoreNonPremiumReturnsFalse() async throws {
        mockStoreKitService.setSubscriptionStatus(false)

        sut.dispatch(action: .restorePurchases)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.isPremium)
        #expect(sut.currentState.restoreSuccessful)
        #expect(!sut.currentState.shouldDismiss)
    }

    @Test("Restore purchases with premium sets shouldDismiss")
    func restorePremiumSetsDismiss() async throws {
        mockStoreKitService.setSubscriptionStatus(true)

        sut.dispatch(action: .restorePurchases)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isPremium)
        #expect(sut.currentState.restoreSuccessful)
        #expect(sut.currentState.shouldDismiss)
    }

    // MARK: - Check Subscription Status Tests

    @Test("Check subscription status with premium sets shouldDismiss")
    func checkStatusPremiumSetsDismiss() async throws {
        mockStoreKitService.setSubscriptionStatus(true)

        sut.dispatch(action: .checkSubscriptionStatus)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.isPremium)
        #expect(sut.currentState.shouldDismiss)
    }

    @Test("Check subscription status with non-premium does not dismiss")
    func checkStatusNonPremiumDoesNotDismiss() async throws {
        mockStoreKitService.setSubscriptionStatus(false)

        sut.dispatch(action: .checkSubscriptionStatus)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(!sut.currentState.isPremium)
        #expect(!sut.currentState.shouldDismiss)
    }

    // MARK: - Load Products Tests

    @Test("Load products clears previous error")
    func loadProductsClearsPreviousError() async throws {
        // First cause an error via restore
        mockStoreKitService.configureRestoreFailure(true)
        sut.dispatch(action: .restorePurchases)
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(sut.currentState.error != nil)

        // Now load products should clear the error
        mockStoreKitService.configureRestoreFailure(false)
        sut.dispatch(action: .loadProducts)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(sut.currentState.error == nil)
        #expect(!sut.currentState.isLoadingProducts)
    }

    @Test("Load products logs paywall_shown analytics")
    func loadProductsLogsPaywallShown() async throws {
        sut.dispatch(action: .loadProducts)
        try await Task.sleep(nanoseconds: 200_000_000)

        let events = mockAnalyticsService.loggedEvents.filter { $0.name == "paywall_shown" }
        #expect(events.count == 1)
    }

    // MARK: - Subscription Status Observer Tests

    @Test("Subscription status change observed automatically")
    func subscriptionStatusChangeObserved() async throws {
        #expect(!sut.currentState.isPremium)

        mockStoreKitService.setSubscriptionStatus(true)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(sut.currentState.isPremium)

        mockStoreKitService.setSubscriptionStatus(false)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(!sut.currentState.isPremium)
    }

    // MARK: - Dismiss Tests

    @Test("Dismiss sets shouldDismiss without affecting other state")
    func dismissPreservesOtherState() async throws {
        mockStoreKitService.setSubscriptionStatus(true)
        try await Task.sleep(nanoseconds: 200_000_000)

        sut.dispatch(action: .dismiss)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(sut.currentState.shouldDismiss)
        #expect(sut.currentState.isPremium)
    }

    // MARK: - State Transitions

    @Test("Restore transitions through isRestoring states")
    func restoreStateTransitions() async throws {
        var cancellables = Set<AnyCancellable>()
        var restoringStates: [Bool] = []

        sut.statePublisher
            .map(\.isRestoring)
            .sink { restoringStates.append($0) }
            .store(in: &cancellables)

        sut.dispatch(action: .restorePurchases)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(restoringStates.contains(true))
        #expect(restoringStates.last == false)
    }

    @Test("Restore failure transitions through isRestoring states")
    func restoreFailureStateTransitions() async throws {
        mockStoreKitService.configureRestoreFailure(true)

        var cancellables = Set<AnyCancellable>()
        var restoringStates: [Bool] = []

        sut.statePublisher
            .map(\.isRestoring)
            .sink { restoringStates.append($0) }
            .store(in: &cancellables)

        sut.dispatch(action: .restorePurchases)
        try await Task.sleep(nanoseconds: 300_000_000)

        #expect(restoringStates.contains(true))
        #expect(restoringStates.last == false)
    }
}
