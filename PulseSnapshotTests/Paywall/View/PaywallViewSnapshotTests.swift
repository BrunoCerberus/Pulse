@testable import Pulse
import Combine
import SnapshotTesting
import StoreKit
import SwiftUI
import XCTest

@MainActor
final class PaywallViewSnapshotTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testPaywallViewLoading() {
        let viewModel = PaywallViewModel(serviceLocator: .preview)

        let view = PaywallView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        // Capture loading state immediately before products load
        assertSnapshot(
            of: controller,
            as: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision),
            record: false
        )
    }

    func testPaywallViewSuccess() {
        let viewModel = PaywallViewModel(serviceLocator: .preview)

        let view = PaywallView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        // Use proper expectation observation instead of arbitrary delay
        let expectation = XCTestExpectation(description: "Wait for view state to settle")

        viewModel.$viewState
            .dropFirst() // Skip initial loading state
            .sink { state in
                if case .success = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Trigger view lifecycle and manually trigger the viewDidAppear event
        // since snapshot tests don't trigger SwiftUI's onAppear modifier
        controller.view.layoutIfNeeded()
        viewModel.handle(event: .viewDidAppear)

        // Wait for state transition or timeout
        wait(for: [expectation], timeout: 5.0)

        assertSnapshot(
            of: controller,
            as: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision),
            record: false
        )
    }

    func testPaywallViewError() {
        // Create a service locator with a failing StoreKit service
        let serviceLocator = createErrorServiceLocator()
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)

        let view = PaywallView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        // Use proper expectation observation for error state
        let expectation = XCTestExpectation(description: "Wait for error state")

        viewModel.$viewState
            .dropFirst() // Skip initial loading state
            .sink { state in
                if case .error = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Trigger view lifecycle and manually trigger the viewDidAppear event
        // since snapshot tests don't trigger SwiftUI's onAppear modifier
        controller.view.layoutIfNeeded()
        viewModel.handle(event: .viewDidAppear)

        // Wait for error state or timeout
        wait(for: [expectation], timeout: 5.0)

        assertSnapshot(
            of: controller,
            as: .image(on: SnapshotConfig.iPhoneAir, precision: SnapshotConfig.standardPrecision),
            record: false
        )
    }

    // MARK: - Helpers

    private func createErrorServiceLocator() -> ServiceLocator {
        let serviceLocator = ServiceLocator()
        serviceLocator.register(NewsService.self, instance: MockNewsService())
        serviceLocator.register(SearchService.self, instance: MockSearchService())
        serviceLocator.register(BookmarksService.self, instance: MockBookmarksService())
        serviceLocator.register(LLMService.self, instance: MockLLMService())
        serviceLocator.register(DigestService.self, instance: MockDigestService())
        serviceLocator.register(ForYouService.self, instance: MockForYouService())
        serviceLocator.register(SettingsService.self, instance: MockSettingsService())
        serviceLocator.register(StorageService.self, instance: MockStorageService())
        serviceLocator.register(StoreKitService.self, instance: FailingStoreKitService())
        serviceLocator.register(RemoteConfigService.self, instance: MockRemoteConfigService())
        serviceLocator.register(AuthService.self, instance: MockAuthService())
        return serviceLocator
    }
}

// MARK: - Failing StoreKit Service

/// A mock StoreKit service that always fails to fetch products.
private final class FailingStoreKitService: StoreKitService {
    private let subscriptionStatusSubject = CurrentValueSubject<Bool, Never>(false)

    var subscriptionStatusPublisher: AnyPublisher<Bool, Never> {
        subscriptionStatusSubject.eraseToAnyPublisher()
    }

    var isPremium: Bool { false }

    func fetchProducts() -> AnyPublisher<[Product], Error> {
        Fail(error: Pulse.StoreKitError.unknown)
            .eraseToAnyPublisher()
    }

    func purchase(_: Product) -> AnyPublisher<Bool, Error> {
        Fail(error: Pulse.StoreKitError.purchaseFailed)
            .eraseToAnyPublisher()
    }

    func restorePurchases() -> AnyPublisher<Bool, Error> {
        Fail(error: Pulse.StoreKitError.unknown)
            .eraseToAnyPublisher()
    }

    func checkSubscriptionStatus() -> AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }
}
