import Combine
import EntropyCore
@testable import Pulse
import SwiftUI
import Testing

@Suite("SignInView Tests")
struct SignInViewTests {
    @Test("SignInView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let view = SignInView(serviceLocator: serviceLocator)
        #expect(view is SignInView)
    }

    @Test("init creates viewModel")
    func initCreatesViewModel() {
        let serviceLocator = ServiceLocator()
        let view = SignInView(serviceLocator: serviceLocator)
        #expect(view.viewModel is SignInViewModel)
    }
}
