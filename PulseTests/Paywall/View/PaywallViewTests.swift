import Combine
import EntropyCore
@testable import Pulse
import StoreKit
import SwiftUI
import Testing

@Suite("PaywallView Tests")
struct PaywallViewTests {
    @Test("PaywallView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        let view = PaywallView(viewModel: viewModel)
        #expect(view is PaywallView)
    }

    @Test("init sets viewModel")
    func initSetsViewModel() {
        let serviceLocator = ServiceLocator()
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        let view = PaywallView(viewModel: viewModel)
        #expect(view.viewModel is PaywallViewModel)
    }

    @Test("isRunningTests returns true in test environment")
    func isRunningTestsReturnsTrueInTestEnvironment() {
        let serviceLocator = ServiceLocator()
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        let view = PaywallView(viewModel: viewModel)

        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] = "/path/to/test/config"

        let isRunningTests = view.isRunningTests

        #expect(isRunningTests == true)

        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] = nil
    }

    @Test("isRunningTests returns false outside test environment")
    func isRunningTestsReturnsFalseOutsideTestEnvironment() {
        let serviceLocator = ServiceLocator()
        let viewModel = PaywallViewModel(serviceLocator: serviceLocator)
        let view = PaywallView(viewModel: viewModel)

        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] = nil

        let isRunningTests = view.isRunningTests

        #expect(isRunningTests == false)
    }
}
