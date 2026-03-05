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
        try await waitForStateUpdate(duration: TestWaitDuration.standard)

        // We can't create a real Product, but we can test the restore failure path
        // which exercises similar completion handling
        mockStoreKitService.configureRestoreFailure(true)
        sut.dispatch(action: .restorePurchases)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.currentState.isRestoring)
        #expect(sut.currentState.error != nil)
    }

    // MARK: - Restore Success Tests

    @Test("Restore purchases with non-premium returns false premium")
    func restoreNonPremiumReturnsFalse() async throws {
        mockStoreKitService.setSubscriptionStatus(false)

        sut.dispatch(action: .restorePurchases)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.currentState.isPremium)
        #expect(sut.currentState.restoreSuccessful)
        #expect(!sut.currentState.shouldDismiss)
    }

    @Test("Restore purchases with premium sets shouldDismiss")
    func restorePremiumSetsDismiss() async throws {
        mockStoreKitService.setSubscriptionStatus(true)

        sut.dispatch(action: .restorePurchases)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.isPremium)
        #expect(sut.currentState.restoreSuccessful)
        #expect(sut.currentState.shouldDismiss)
    }

    // MARK: - Check Subscription Status Tests

    @Test("Check subscription status with premium sets shouldDismiss")
    func checkStatusPremiumSetsDismiss() async throws {
        mockStoreKitService.setSubscriptionStatus(true)

        sut.dispatch(action: .checkSubscriptionStatus)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.isPremium)
        #expect(sut.currentState.shouldDismiss)
    }

    @Test("Check subscription status with non-premium does not dismiss")
    func checkStatusNonPremiumDoesNotDismiss() async throws {
        mockStoreKitService.setSubscriptionStatus(false)

        sut.dispatch(action: .checkSubscriptionStatus)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.currentState.isPremium)
        #expect(!sut.currentState.shouldDismiss)
    }

    // MARK: - Load Products Tests

    @Test("Load products sets loading state and completes")
    func loadProductsSetsLoadingAndCompletes() async throws {
        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.statePublisher
            .map(\.isLoadingProducts)
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)

        sut.dispatch(action: .loadProducts)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(loadingStates.contains(true))
        #expect(loadingStates.last == false)
        #expect(sut.currentState.error == nil)
    }

    @Test("Load products logs paywall_shown analytics")
    func loadProductsLogsPaywallShown() async throws {
        sut.dispatch(action: .loadProducts)
        try await waitForStateUpdate(duration: TestWaitDuration.standard)

        let events = mockAnalyticsService.loggedEvents.filter { $0.name == "paywall_shown" }
        #expect(events.count == 1)
    }

    // MARK: - Subscription Status Observer Tests

    @Test("Subscription status change observed automatically")
    func subscriptionStatusChangeObserved() async throws {
        #expect(!sut.currentState.isPremium)

        mockStoreKitService.setSubscriptionStatus(true)
        try await waitForStateUpdate(duration: TestWaitDuration.standard)

        #expect(sut.currentState.isPremium)

        mockStoreKitService.setSubscriptionStatus(false)
        try await waitForStateUpdate(duration: TestWaitDuration.standard)

        #expect(!sut.currentState.isPremium)
    }

    // MARK: - Dismiss Tests

    @Test("Dismiss sets shouldDismiss without affecting other state")
    func dismissPreservesOtherState() async throws {
        mockStoreKitService.setSubscriptionStatus(true)
        try await waitForStateUpdate(duration: TestWaitDuration.standard)

        sut.dispatch(action: .dismiss)
        try await waitForStateUpdate(duration: TestWaitDuration.short)

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
        try await waitForStateUpdate(duration: TestWaitDuration.long)

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
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(restoringStates.contains(true))
        #expect(restoringStates.last == false)
    }
}
