import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class OnboardingSnapshotTests: XCTestCase {
    private var serviceLocator: ServiceLocator!

    override func setUp() async throws {
        try await super.setUp()
        serviceLocator = ServiceLocator()
        serviceLocator.register(OnboardingService.self, instance: MockOnboardingService())
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
        serviceLocator.register(SettingsService.self, instance: MockSettingsService())
    }

    func testOnboardingWelcomePageDark() {
        let viewModel = OnboardingViewModel(serviceLocator: serviceLocator)
        let view = OnboardingView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }

    func testOnboardingGetStartedPageDark() {
        let viewModel = OnboardingViewModel(serviceLocator: serviceLocator)
        viewModel.handle(event: .onPageChanged(.getStarted))

        let view = OnboardingView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }

    func testOnboardingWelcomePageLight() {
        let viewModel = OnboardingViewModel(serviceLocator: serviceLocator)
        let view = OnboardingView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAirLight),
            record: false
        )
    }

    func testOnboardingChooseTopicsPageEmpty() {
        let viewModel = OnboardingViewModel(serviceLocator: serviceLocator)
        viewModel.handle(event: .onPageChanged(.chooseTopics))

        let view = OnboardingView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }

    func testOnboardingChooseTopicsPageSomeSelected() {
        let viewModel = OnboardingViewModel(serviceLocator: serviceLocator)
        viewModel.handle(event: .onPageChanged(.chooseTopics))
        viewModel.handle(event: .onToggleTopic(.technology))
        viewModel.handle(event: .onToggleTopic(.science))
        viewModel.handle(event: .onToggleTopic(.business))

        let view = OnboardingView(viewModel: viewModel)
        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }
}
