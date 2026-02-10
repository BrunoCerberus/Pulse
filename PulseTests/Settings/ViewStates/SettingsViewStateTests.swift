import Foundation
@testable import Pulse
import Testing

@Suite("SettingsViewState Tests")
struct SettingsViewStateTests {
    @Test("Initial state has correct defaults")
    func initialState() {
        let state = SettingsViewState.initial

        #expect(state.mutedSources.isEmpty)
        #expect(state.mutedKeywords.isEmpty)
        #expect(state.notificationsEnabled)
        #expect(state.breakingNewsEnabled)
        #expect(!state.isDarkMode)
        #expect(state.useSystemTheme)
        #expect(!state.isLoading)
        #expect(!state.showSignOutConfirmation)
        #expect(state.currentUser == nil)
        #expect(state.errorMessage == nil)
        #expect(state.newMutedSource == "")
        #expect(state.newMutedKeyword == "")
    }

    @Test("SettingsViewState is Equatable")
    func equatable() {
        let state1 = SettingsViewState.initial
        let state2 = SettingsViewState.initial

        #expect(state1 == state2)
    }

    @Test("Modified state is not equal to initial")
    func modifiedNotEqual() {
        var state = SettingsViewState.initial
        state.isDarkMode = true

        #expect(state != SettingsViewState.initial)
    }
}

@Suite("SettingsViewEvent Tests")
struct SettingsViewEventTests {
    @Test("SettingsViewEvent cases are Equatable")
    func equatable() {
        #expect(SettingsViewEvent.onAppear == SettingsViewEvent.onAppear)
        #expect(SettingsViewEvent.onSignOutTapped == SettingsViewEvent.onSignOutTapped)
        #expect(SettingsViewEvent.onConfirmSignOut == SettingsViewEvent.onConfirmSignOut)
        #expect(SettingsViewEvent.onCancelSignOut == SettingsViewEvent.onCancelSignOut)
        #expect(SettingsViewEvent.onAddMutedSource == SettingsViewEvent.onAddMutedSource)
        #expect(SettingsViewEvent.onAddMutedKeyword == SettingsViewEvent.onAddMutedKeyword)
    }

    @Test("Toggle events carry boolean values")
    func toggleEventsCarryValues() {
        #expect(SettingsViewEvent.onToggleNotifications(true) == SettingsViewEvent.onToggleNotifications(true))
        #expect(SettingsViewEvent.onToggleNotifications(true) != SettingsViewEvent.onToggleNotifications(false))
        #expect(SettingsViewEvent.onToggleBreakingNews(true) != SettingsViewEvent.onToggleBreakingNews(false))
        #expect(SettingsViewEvent.onToggleDarkMode(true) != SettingsViewEvent.onToggleDarkMode(false))
        #expect(SettingsViewEvent.onToggleSystemTheme(true) != SettingsViewEvent.onToggleSystemTheme(false))
    }

    @Test("Muted source events carry string values")
    func mutedSourceEventsCarryValues() {
        let event1 = SettingsViewEvent.onNewMutedSourceChanged("CNN")
        let event2 = SettingsViewEvent.onNewMutedSourceChanged("CNN")
        let event3 = SettingsViewEvent.onNewMutedSourceChanged("BBC")

        #expect(event1 == event2)
        #expect(event1 != event3)

        #expect(SettingsViewEvent.onRemoveMutedSource("CNN") == SettingsViewEvent.onRemoveMutedSource("CNN"))
        #expect(SettingsViewEvent.onRemoveMutedSource("CNN") != SettingsViewEvent.onRemoveMutedSource("BBC"))
    }

    @Test("Muted keyword events carry string values")
    func mutedKeywordEventsCarryValues() {
        let event1 = SettingsViewEvent.onNewMutedKeywordChanged("politics")
        let event2 = SettingsViewEvent.onNewMutedKeywordChanged("politics")
        let event3 = SettingsViewEvent.onNewMutedKeywordChanged("sports")

        #expect(event1 == event2)
        #expect(event1 != event3)

        #expect(SettingsViewEvent.onRemoveMutedKeyword("politics") == SettingsViewEvent.onRemoveMutedKeyword("politics"))
    }

    @Test("Different event types are not equal")
    func differentTypesNotEqual() {
        #expect(SettingsViewEvent.onAppear != SettingsViewEvent.onSignOutTapped)
        #expect(SettingsViewEvent.onConfirmSignOut != SettingsViewEvent.onCancelSignOut)
        #expect(SettingsViewEvent.onAddMutedSource != SettingsViewEvent.onAddMutedKeyword)
    }
}
