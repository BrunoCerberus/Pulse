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
        _ = PaywallView(viewModel: viewModel)
    }

    // Note: Testing @StateObject property access outside a View hierarchy is not supported
    // by SwiftUI (triggers "Accessing StateObject's object without being installed on a View").
    // The canBeInstantiated() test above already covers that the view can be created with a viewModel.
}
