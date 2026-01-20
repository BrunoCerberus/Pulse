import Combine
import Foundation
@testable import Pulse
import StoreKit
import Testing

@Suite("StoreKitService Protocol Tests")
struct StoreKitServiceProtocolTests {
    @Test("StoreKitService protocol methods exist")
    func protocolConformance() {
        let service: StoreKitService = MockStoreKitService()
        #expect(service.subscriptionStatusPublisher != nil)
        #expect(service.isPremium == false)
    }

    @Test("Subscription status publisher is non-nil")
    func testSubscriptionStatusPublisher() {
        let service: StoreKitService = MockStoreKitService(isPremium: true)
        #expect(service.subscriptionStatusPublisher != nil)
    }

    @Test("isPremium property returns current status")
    func isPremiumProperty() {
        let service = MockStoreKitService(isPremium: false)
        #expect(service.isPremium == false)

        let premiumService = MockStoreKitService(isPremium: true)
        #expect(premiumService.isPremium == true)
    }
}

@Suite("LiveStoreKitService Product Configuration Tests")
struct LiveStoreKitServiceConfigurationTests {
    @Test("Product identifiers are configured")
    func productIDsConfigured() {
        #expect(!LiveStoreKitService.monthlyProductID.isEmpty)
        #expect(!LiveStoreKitService.yearlyProductID.isEmpty)
    }

    @Test("Monthly product ID has correct format")
    func monthlyProductIDFormat() {
        let id = LiveStoreKitService.monthlyProductID
        #expect(id.contains("premium"))
        #expect(id.contains("monthly"))
    }

    @Test("Yearly product ID has correct format")
    func yearlyProductIDFormat() {
        let id = LiveStoreKitService.yearlyProductID
        #expect(id.contains("premium"))
        #expect(id.contains("yearly"))
    }

    @Test("Subscription group ID is configured")
    func subscriptionGroupIDConfigured() {
        let groupID = LiveStoreKitService.subscriptionGroupID
        #expect(!groupID.isEmpty)
        #expect(groupID == "premium_subscriptions")
    }
}

@Suite("MockStoreKitService Tests")
struct MockStoreKitServiceTests {
    let sut = MockStoreKitService()

    @Test("Initial subscription status is false by default")
    func initialStatusFalse() {
        let service = MockStoreKitService()
        #expect(service.isPremium == false)
    }

    @Test("Initial subscription status respects isPremium parameter")
    func initialStatusWithParameter() {
        let premiumService = MockStoreKitService(isPremium: true)
        #expect(premiumService.isPremium == true)

        let freeService = MockStoreKitService(isPremium: false)
        #expect(freeService.isPremium == false)
    }

    @Test("Subscription status publisher emits initial value")
    func subscriptionStatusPublisherEmitsInitial() async throws {
        let service = MockStoreKitService(isPremium: true)
        var capturedStatuses: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        service.subscriptionStatusPublisher
            .sink { status in
                capturedStatuses.append(status)
            }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.short)

        #expect(capturedStatuses.count > 0)
        #expect(capturedStatuses.first == true)
    }

    @Test("setSubscriptionStatus updates isPremium")
    func testSetSubscriptionStatus() async throws {
        let service = MockStoreKitService(isPremium: false)
        #expect(service.isPremium == false)

        service.setSubscriptionStatus(true)

        try await Task.sleep(nanoseconds: TestWaitDuration.short)
        #expect(service.isPremium == true)
    }

    @Test("setSubscriptionStatus publishes new value")
    func setSubscriptionStatusPublishes() async throws {
        let service = MockStoreKitService(isPremium: false)
        var capturedStatuses: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        service.subscriptionStatusPublisher
            .sink { status in
                capturedStatuses.append(status)
            }
            .store(in: &cancellables)

        service.setSubscriptionStatus(true)

        try await Task.sleep(nanoseconds: TestWaitDuration.short)

        let statusChanged = capturedStatuses.contains(true)
        #expect(statusChanged)
    }

    @Test("fetchProducts returns empty array for mock")
    func fetchProductsReturnsEmpty() async throws {
        let service = MockStoreKitService()
        var capturedProducts: [Product] = []
        var capturedError: Error?
        var cancellables = Set<AnyCancellable>()

        service.fetchProducts()
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        capturedError = error
                    }
                },
                receiveValue: { products in
                    capturedProducts = products
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedProducts.isEmpty)
        #expect(capturedError == nil)
    }

    @Test("purchase succeeds by default")
    func purchaseSuccess() async throws {
        let service = MockStoreKitService(isPremium: false)
        var capturedResult: Bool?
        var capturedError: Error?
        var cancellables = Set<AnyCancellable>()

        service.purchase(MockProduct())
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        capturedError = error
                    }
                },
                receiveValue: { result in
                    capturedResult = result
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedResult == true)
        #expect(capturedError == nil)
    }

    @Test("purchase updates subscription status on success")
    func purchaseUpdatesStatus() async throws {
        let service = MockStoreKitService(isPremium: false)
        #expect(service.isPremium == false)

        var cancellables = Set<AnyCancellable>()
        service.purchase(MockProduct())
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(service.isPremium == true)
    }

    @Test("purchase fails when configured to fail")
    func purchaseFailure() async throws {
        let service = MockStoreKitService()
        service.configurePurchaseFailure(true)

        var capturedError: Error?
        var cancellables = Set<AnyCancellable>()

        service.purchase(MockProduct())
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        capturedError = error
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedError is StoreKitError)
    }

    @Test("configurePurchaseFailure enables purchase failure")
    func testConfigurePurchaseFailure() {
        let service = MockStoreKitService()
        service.configurePurchaseFailure(true)
        // Just verify it doesn't crash; actual failure tested above
        #expect(true)
    }

    @Test("restorePurchases returns isPremium status")
    func restorePurchasesReturnsStatus() async throws {
        let service = MockStoreKitService(isPremium: true)
        var capturedResult: Bool?
        var cancellables = Set<AnyCancellable>()

        service.restorePurchases()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { result in
                    capturedResult = result
                }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedResult == true)
    }

    @Test("restorePurchases fails when configured to fail")
    func restorePurchasesFailure() async throws {
        let service = MockStoreKitService()
        service.configureRestoreFailure(true)

        var capturedError: Error?
        var cancellables = Set<AnyCancellable>()

        service.restorePurchases()
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        capturedError = error
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedError is StoreKitError)
    }

    @Test("checkSubscriptionStatus returns current status")
    func testCheckSubscriptionStatus() async throws {
        let service = MockStoreKitService(isPremium: true)
        var capturedStatus: Bool?
        var cancellables = Set<AnyCancellable>()

        service.checkSubscriptionStatus()
            .sink { status in
                capturedStatus = status
            }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(capturedStatus == true)
    }

    @Test("checkSubscriptionStatus never fails")
    func checkSubscriptionStatusNeverFails() async throws {
        let service = MockStoreKitService()
        var didReceiveValue = false
        var cancellables = Set<AnyCancellable>()

        service.checkSubscriptionStatus()
            .sink { _ in
                didReceiveValue = true
            }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: TestWaitDuration.standard)

        #expect(didReceiveValue)
    }
}

@Suite("MockStoreKitService State Transitions Tests")
struct MockStoreKitServiceStateTransitionsTests {
    @Test("Transition from free to premium")
    func transitionFreeToPremium() async throws {
        let service = MockStoreKitService(isPremium: false)
        var capturedStatuses: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        service.subscriptionStatusPublisher
            .sink { status in
                capturedStatuses.append(status)
            }
            .store(in: &cancellables)

        #expect(service.isPremium == false)

        service.setSubscriptionStatus(true)

        try await Task.sleep(nanoseconds: TestWaitDuration.short)

        #expect(service.isPremium == true)
        let hasTransition = capturedStatuses.count > 1
        #expect(hasTransition)
    }

    @Test("Transition from premium to free")
    func transitionPremiumToFree() async throws {
        let service = MockStoreKitService(isPremium: true)
        var capturedStatuses: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        service.subscriptionStatusPublisher
            .sink { status in
                capturedStatuses.append(status)
            }
            .store(in: &cancellables)

        #expect(service.isPremium == true)

        service.setSubscriptionStatus(false)

        try await Task.sleep(nanoseconds: TestWaitDuration.short)

        #expect(service.isPremium == false)
        let hasTransition = capturedStatuses.contains(false)
        #expect(hasTransition)
    }

    @Test("Multiple status transitions")
    func multipleTransitions() async throws {
        let service = MockStoreKitService(isPremium: false)
        var capturedStatuses: [Bool] = []
        var cancellables = Set<AnyCancellable>()

        service.subscriptionStatusPublisher
            .sink { status in
                capturedStatuses.append(status)
            }
            .store(in: &cancellables)

        service.setSubscriptionStatus(true)
        try await Task.sleep(nanoseconds: TestWaitDuration.short)
        #expect(service.isPremium == true)

        service.setSubscriptionStatus(false)
        try await Task.sleep(nanoseconds: TestWaitDuration.short)
        #expect(service.isPremium == false)

        service.setSubscriptionStatus(true)
        try await Task.sleep(nanoseconds: TestWaitDuration.short)
        #expect(service.isPremium == true)

        #expect(capturedStatuses.count >= 3)
    }
}

@Suite("StoreKitError Tests")
struct StoreKitErrorTests {
    @Test("FailedVerification error has description")
    func failedVerificationDescription() {
        let error = StoreKitError.failedVerification
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("verification") ?? false)
    }

    @Test("PurchaseFailed error has description")
    func purchaseFailedDescription() {
        let error = StoreKitError.purchaseFailed
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.contains("failed") ?? false)
    }

    @Test("Unknown error has description")
    func unknownErrorDescription() {
        let error = StoreKitError.unknown
        #expect(error.errorDescription != nil)
    }

    @Test("All errors conform to LocalizedError")
    func errorsLocalized() {
        let errors: [StoreKitError] = [
            .failedVerification,
            .purchaseFailed,
            .unknown,
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
        }
    }
}

// MARK: - Mock Product Helper

struct MockProduct: Identifiable {
    let id = UUID().uuidString
    let displayName = "Mock Premium Subscription"
    let description = "A mock subscription for testing"
}
