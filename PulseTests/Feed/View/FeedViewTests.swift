import Combine
import EntropyCore
@testable import Pulse
import SwiftUI
import Testing

@Suite("FeedView Tests")
struct FeedViewTests {
    @Test("FeedView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let viewModel = FeedViewModel(serviceLocator: serviceLocator)
        let router = FeedNavigationRouter()
        let view = FeedView(router: router, viewModel: viewModel, serviceLocator: serviceLocator)
        #expect(view is FeedView)
    }

    @Test("init sets router")
    func initSetsRouter() {
        let serviceLocator = ServiceLocator()
        let viewModel = FeedViewModel(serviceLocator: serviceLocator)
        let router = FeedNavigationRouter()
        let view = FeedView(router: router, viewModel: viewModel, serviceLocator: serviceLocator)
        #expect(view.router is FeedNavigationRouter)
    }

    @Test("init sets serviceLocator")
    func initSetsServiceLocator() {
        let serviceLocator = ServiceLocator()
        let viewModel = FeedViewModel(serviceLocator: serviceLocator)
        let router = FeedNavigationRouter()
        let view = FeedView(router: router, viewModel: viewModel, serviceLocator: serviceLocator)
        #expect(view.serviceLocator === serviceLocator)
    }
}
