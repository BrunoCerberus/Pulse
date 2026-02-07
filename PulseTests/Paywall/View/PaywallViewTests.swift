import Combine
import EntropyCore
@testable import Pulse
import StoreKit
import SwiftUI
import Testing

@Suite("PaywallView Tests")
@MainActor
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
}
