import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("RootView Tests")
struct RootViewTests {
    @Test("RootView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let view = RootView(serviceLocator: serviceLocator)
        #expect(view.serviceLocator === serviceLocator)
    }

    @Test("init sets serviceLocator")
    func initSetsServiceLocator() {
        let serviceLocator = ServiceLocator()
        let view = RootView(serviceLocator: serviceLocator)
        #expect(view.serviceLocator === serviceLocator)
    }
}
