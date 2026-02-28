import EntropyCore
@testable import Pulse
import SwiftUI
import Testing

@Suite("PremiumGateView Tests")
struct PremiumGateViewTests {
    @Test("PremiumGateView can be instantiated")
    func canBeInstantiated() {
        let serviceLocator = ServiceLocator()
        let view = PremiumGateView(feature: .dailyDigest, serviceLocator: serviceLocator)
        #expect(view.feature == .dailyDigest)
    }

    @Test("init sets feature")
    func initSetsFeature() {
        let serviceLocator = ServiceLocator()
        let view = PremiumGateView(feature: .articleSummarization, serviceLocator: serviceLocator)
        #expect(view.feature == .articleSummarization)
    }

    @Test("init sets serviceLocator")
    func initSetsServiceLocator() {
        let serviceLocator = ServiceLocator()
        let view = PremiumGateView(feature: .dailyDigest, serviceLocator: serviceLocator)
        #expect(view.serviceLocator === serviceLocator)
    }

    @Test("init sets onUnlockTapped callback")
    func initSetsOnUnlockTapped() {
        let serviceLocator = ServiceLocator()
        let view = PremiumGateView(
            feature: .dailyDigest,
            serviceLocator: serviceLocator,
            onUnlockTapped: {}
        )
        #expect(view.onUnlockTapped != nil)
    }
}
