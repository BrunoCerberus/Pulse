import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("ForYouSettingsViewModel Tests")
@MainActor
struct ForYouSettingsViewModelTests {
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

    @Test("Initial state is hidden empty/loading false")
    func initialState() {
        let sut = ForYouSettingsViewModel(serviceLocator: serviceLocator)
        #expect(sut.viewState.rows.isEmpty)
        #expect(sut.viewState.showEmptyState == false)
        #expect(sut.viewState.showResetConfirmation == false)
    }

    @Test("Loaded topics are mapped to rows with formatted weight labels")
    func topicsMapToRows() async throws {
        try await mockProfile.upsert(
            topicID: "ai", displayName: "AI", weightDelta: 2.4,
            source: .extracted, category: nil,
        )
        let sut = ForYouSettingsViewModel(serviceLocator: serviceLocator)

        sut.handle(event: .onAppear)
        let loaded = await waitForMainActorCondition { [sut] in
            !sut.viewState.rows.isEmpty
        }
        #expect(loaded)
        let row = try #require(sut.viewState.rows.first)
        #expect(row.id == "ai")
        #expect(row.displayName == "AI")
        #expect(row.weightLabel == "2.4")
        #expect(row.sourceLabel == "Extracted")
    }

    @Test("Empty profile yields showEmptyState true")
    func emptyProfileShowsEmptyState() async {
        let sut = ForYouSettingsViewModel(serviceLocator: serviceLocator)
        sut.handle(event: .onAppear)
        let empty = await waitForMainActorCondition { [sut] in
            sut.viewState.showEmptyState
        }
        #expect(empty)
    }

    @Test("Display-name fallback uses kebab-case humanizer when stored name is empty")
    func emptyDisplayNameFallsBackToHumanizer() async throws {
        try await mockProfile.upsert(
            topicID: "artificial-intelligence", displayName: "", weightDelta: 1,
            source: .extracted, category: nil,
        )
        let sut = ForYouSettingsViewModel(serviceLocator: serviceLocator)
        sut.handle(event: .onAppear)
        let loaded = await waitForMainActorCondition { [sut] in
            !sut.viewState.rows.isEmpty
        }
        #expect(loaded)
        #expect(sut.viewState.rows.first?.displayName == "Artificial Intelligence")
    }

    @Test("onResetTapped surfaces showResetConfirmation in view state")
    func resetTapShowsConfirmation() async {
        let sut = ForYouSettingsViewModel(serviceLocator: serviceLocator)
        sut.handle(event: .onResetTapped)
        let visible = await waitForMainActorCondition { [sut] in
            sut.viewState.showResetConfirmation
        }
        #expect(visible)
    }

    @Test("onResetConfirmed wipes rows")
    func confirmResetWipesRows() async throws {
        try await mockProfile.upsert(
            topicID: "ai", displayName: "AI", weightDelta: 1,
            source: .seed, category: nil,
        )
        let sut = ForYouSettingsViewModel(serviceLocator: serviceLocator)
        sut.handle(event: .onAppear)
        _ = await waitForMainActorCondition { [sut] in
            !sut.viewState.rows.isEmpty
        }

        sut.handle(event: .onResetTapped)
        sut.handle(event: .onResetConfirmed)

        let wiped = await waitForMainActorCondition { [sut] in
            sut.viewState.rows.isEmpty
                && sut.viewState.showEmptyState
                && sut.viewState.showResetConfirmation == false
        }
        #expect(wiped)
    }

    @Test("onRemoveTopic removes that row")
    func removeTopicRemovesRow() async throws {
        try await mockProfile.upsert(
            topicID: "ai", displayName: "AI", weightDelta: 1,
            source: .seed, category: nil,
        )
        try await mockProfile.upsert(
            topicID: "climate", displayName: "Climate", weightDelta: 1,
            source: .seed, category: nil,
        )
        let sut = ForYouSettingsViewModel(serviceLocator: serviceLocator)
        sut.handle(event: .onAppear)
        _ = await waitForMainActorCondition { [sut] in
            sut.viewState.rows.count == 2
        }

        sut.handle(event: .onRemoveTopic(topicID: "ai"))
        let removed = await waitForMainActorCondition { [sut] in
            sut.viewState.rows.count == 1 && sut.viewState.rows.first?.id == "climate"
        }
        #expect(removed)
    }
}
