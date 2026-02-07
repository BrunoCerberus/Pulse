import Combine
import EntropyCore
@testable import Pulse
import SwiftUI
import Testing

@Suite("FeedView Tests")
@MainActor
struct FeedViewTests {
    @Test("FeedView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let viewModel = FeedViewModel(serviceLocator: serviceLocator)
        let router = FeedNavigationRouter()
        let view = FeedView(router: router, viewModel: viewModel, serviceLocator: serviceLocator)
        #expect(view is FeedView)
    }
}
