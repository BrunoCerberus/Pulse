import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ForYouSettingsDomainInteractor Tests")
@MainActor
struct ForYouSettingsDomainInteractorTests {
    let serviceLocator: ServiceLocator
    let mockProfile: MockInterestProfileService

    init() {
        serviceLocator = ServiceLocator()
        mockProfile = MockInterestProfileService()
        serviceLocator.register(InterestProfileService.self, instance: mockProfile)
        serviceLocator.register(AnalyticsService.self, instance: MockAnalyticsService())
    }

    private func waitForMainActorCondition(_ predicate: @MainActor @escaping () -> Bool) async -> Bool {
        await waitForCondition(timeout: TestWaitDuration.long, condition: predicate)
    }

    @Test("Initial state is empty and not loading")
    func initialState() {
        let sut = ForYouSettingsDomainInteractor(serviceLocator: serviceLocator)
        #expect(sut.currentState.topics.isEmpty)
        #expect(sut.currentState.isLoading == false)
        #expect(sut.currentState.error == nil)
        #expect(sut.currentState.showResetConfirmation == false)
    }

    @Test("loadProfile populates topics from the service")
    func loadProfilePopulatesTopics() async throws {
        try await mockProfile.upsert(
            topicID: "ai", displayName: "AI", weightDelta: 2,
            source: .extracted, category: nil
        )
        try await mockProfile.upsert(
            topicID: "climate", displayName: "Climate", weightDelta: 1,
            source: .seed, category: "world"
        )
        let sut = ForYouSettingsDomainInteractor(serviceLocator: serviceLocator)

        sut.dispatch(action: .loadProfile)
        let loaded = await waitForMainActorCondition { [sut] in
            sut.currentState.topics.count == 2
        }
        #expect(loaded)
        #expect(Set(sut.currentState.topics.map(\.topicID)) == ["ai", "climate"])
    }

    @Test("loadProfile surfaces fetch errors")
    func loadProfileSurfacesError() async {
        struct Boom: Error, LocalizedError {
            var errorDescription: String? {
                "fetch boom"
            }
        }
        mockProfile.fetchProfileError = Boom()
        let sut = ForYouSettingsDomainInteractor(serviceLocator: serviceLocator)

        sut.dispatch(action: .loadProfile)
        let errored = await waitForMainActorCondition { [sut] in
            sut.currentState.error != nil
        }
        #expect(errored)
        #expect(sut.currentState.topics.isEmpty)
        #expect(sut.currentState.isLoading == false)
    }

    @Test("removeTopic deletes the row via the service")
    func removeTopicDeletesRow() async throws {
        try await mockProfile.upsert(
            topicID: "ai", displayName: "AI", weightDelta: 1,
            source: .seed, category: nil
        )
        try await mockProfile.upsert(
            topicID: "climate", displayName: "Climate", weightDelta: 1,
            source: .seed, category: nil
        )
        let sut = ForYouSettingsDomainInteractor(serviceLocator: serviceLocator)
        sut.dispatch(action: .loadProfile)
        _ = await waitForMainActorCondition { [sut] in
            sut.currentState.topics.count == 2
        }

        sut.dispatch(action: .removeTopic(topicID: "ai"))
        // The service posts `.interestProfileDidChange` on remove, which
        // triggers a reload — so we wait for the topic count to drop.
        let updated = await waitForMainActorCondition { [sut] in
            sut.currentState.topics.count == 1 && sut.currentState.topics.first?.topicID == "climate"
        }
        #expect(updated)
    }

    @Test("requestReset shows the confirmation alert")
    func requestResetShowsAlert() {
        let sut = ForYouSettingsDomainInteractor(serviceLocator: serviceLocator)
        sut.dispatch(action: .requestReset)
        #expect(sut.currentState.showResetConfirmation == true)
    }

    @Test("cancelReset hides the confirmation alert")
    func cancelResetHidesAlert() {
        let sut = ForYouSettingsDomainInteractor(serviceLocator: serviceLocator)
        sut.dispatch(action: .requestReset)
        sut.dispatch(action: .cancelReset)
        #expect(sut.currentState.showResetConfirmation == false)
    }

    @Test("confirmReset wipes the profile and dismisses the alert")
    func confirmResetWipesProfile() async throws {
        try await mockProfile.upsert(
            topicID: "ai", displayName: "AI", weightDelta: 1,
            source: .seed, category: nil
        )
        let sut = ForYouSettingsDomainInteractor(serviceLocator: serviceLocator)
        sut.dispatch(action: .loadProfile)
        _ = await waitForMainActorCondition { [sut] in
            !sut.currentState.topics.isEmpty
        }

        sut.dispatch(action: .requestReset)
        sut.dispatch(action: .confirmReset)

        let cleared = await waitForMainActorCondition { [sut, mockProfile] in
            sut.currentState.topics.isEmpty
                && sut.currentState.showResetConfirmation == false
                && mockProfile.topics.isEmpty
        }
        #expect(cleared)
    }

    @Test("Receives interestProfileDidChange and reloads")
    func reloadsOnProfileChange() async throws {
        let sut = ForYouSettingsDomainInteractor(serviceLocator: serviceLocator)
        sut.dispatch(action: .loadProfile)
        _ = await waitForMainActorCondition { [sut] in
            sut.currentState.isLoading == false
        }

        try await mockProfile.upsert(
            topicID: "external", displayName: "External", weightDelta: 1,
            source: .extracted, category: nil
        )
        // The mock posts the notification on upsert; the interactor should
        // pick it up and refetch.
        let reloaded = await waitForMainActorCondition { [sut] in
            sut.currentState.topics.contains { $0.topicID == "external" }
        }
        #expect(reloaded)
    }
}
