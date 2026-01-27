import Foundation
@testable import Pulse
import Testing

@Suite("SettingsDomainState Tests")
struct SettingsDomainStateTests {
    @Test("Initial state has correct default values")
    func initialState() {
        let state = SettingsDomainState.initial

        #expect(state.preferences == .default)
        #expect(state.isLoading == false)
        #expect(state.isSaving == false)
        #expect(state.error == nil)
        #expect(state.showClearHistoryConfirmation == false)
        #expect(state.showSignOutConfirmation == false)
        #expect(state.newMutedSource == "")
        #expect(state.newMutedKeyword == "")
    }

    @Test("Preferences can be set")
    func preferencesCanBeSet() {
        var state = SettingsDomainState.initial
        var prefs = UserPreferences.default
        prefs.notificationsEnabled = true
        state.preferences = prefs

        #expect(state.preferences.notificationsEnabled == true)
    }

    @Test("isLoading can be set")
    func isLoadingCanBeSet() {
        var state = SettingsDomainState.initial
        state.isLoading = true
        #expect(state.isLoading == true)
    }

    @Test("isSaving can be set")
    func isSavingCanBeSet() {
        var state = SettingsDomainState.initial
        state.isSaving = true
        #expect(state.isSaving == true)
    }

    @Test("Error can be set")
    func errorCanBeSet() {
        var state = SettingsDomainState.initial
        state.error = "Save failed"
        #expect(state.error == "Save failed")
    }

    @Test("Show clear history confirmation can be set")
    func showClearHistoryConfirmationCanBeSet() {
        var state = SettingsDomainState.initial
        state.showClearHistoryConfirmation = true
        #expect(state.showClearHistoryConfirmation == true)
    }

    @Test("Show sign out confirmation can be set")
    func showSignOutConfirmationCanBeSet() {
        var state = SettingsDomainState.initial
        state.showSignOutConfirmation = true
        #expect(state.showSignOutConfirmation == true)
    }

    @Test("New muted source can be set")
    func newMutedSourceCanBeSet() {
        var state = SettingsDomainState.initial
        state.newMutedSource = "Example Source"
        #expect(state.newMutedSource == "Example Source")
    }

    @Test("New muted keyword can be set")
    func newMutedKeywordCanBeSet() {
        var state = SettingsDomainState.initial
        state.newMutedKeyword = "spam"
        #expect(state.newMutedKeyword == "spam")
    }

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        let state1 = SettingsDomainState.initial
        let state2 = SettingsDomainState.initial
        #expect(state1 == state2)
    }

    @Test("States with different isLoading are not equal")
    func differentIsLoading() {
        let state1 = SettingsDomainState.initial
        var state2 = SettingsDomainState.initial
        state2.isLoading = true
        #expect(state1 != state2)
    }

    @Test("States with different isSaving are not equal")
    func differentIsSaving() {
        let state1 = SettingsDomainState.initial
        var state2 = SettingsDomainState.initial
        state2.isSaving = true
        #expect(state1 != state2)
    }

    @Test("States with different showClearHistoryConfirmation are not equal")
    func differentShowClearHistoryConfirmation() {
        let state1 = SettingsDomainState.initial
        var state2 = SettingsDomainState.initial
        state2.showClearHistoryConfirmation = true
        #expect(state1 != state2)
    }
}
