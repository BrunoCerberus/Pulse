import Foundation
@testable import Pulse
import Testing

@Suite("SettingsDomainState Initialization Tests")
struct SettingsDomainStateInitializationTests {
    @Test("Initial preferences are defaults")
    func initialPreferencesAreDefaults() {
        let state = SettingsDomainState()
        #expect(state.preferences == UserPreferences.default)
    }

    @Test("Initial isLoading is false")
    func initialIsLoadingFalse() {
        let state = SettingsDomainState()
        #expect(!state.isLoading)
    }

    @Test("Initial isSaving is false")
    func initialIsSavingFalse() {
        let state = SettingsDomainState()
        #expect(!state.isSaving)
    }

    @Test("Initial error is nil")
    func initialErrorNil() {
        let state = SettingsDomainState()
        #expect(state.error == nil)
    }

    @Test("Initial showClearHistoryConfirmation is false")
    func initialShowClearHistoryConfirmationFalse() {
        let state = SettingsDomainState()
        #expect(!state.showClearHistoryConfirmation)
    }

    @Test("Initial showSignOutConfirmation is false")
    func initialShowSignOutConfirmationFalse() {
        let state = SettingsDomainState()
        #expect(!state.showSignOutConfirmation)
    }

    @Test("Initial newMutedSource is empty")
    func initialNewMutedSourceEmpty() {
        let state = SettingsDomainState()
        #expect(state.newMutedSource.isEmpty)
    }

    @Test("Initial newMutedKeyword is empty")
    func initialNewMutedKeywordEmpty() {
        let state = SettingsDomainState()
        #expect(state.newMutedKeyword.isEmpty)
    }
}

@Suite("SettingsDomainState Preferences Tests")
struct SettingsDomainStatePreferencesTests {
    @Test("Can set custom preferences")
    func setCustomPreferences() {
        var state = SettingsDomainState()
        var prefs = UserPreferences.default
        prefs.theme = .dark
        state.preferences = prefs
        #expect(state.preferences.theme == .dark)
    }

    @Test("Can update preferences theme")
    func updatePreferencesTheme() {
        var state = SettingsDomainState()
        var prefs = state.preferences
        prefs.theme = .light
        state.preferences = prefs
        #expect(state.preferences.theme == .light)
    }

    @Test("Can reset preferences to default")
    func resetPreferencesToDefault() {
        var state = SettingsDomainState()
        var prefs = UserPreferences.default
        prefs.theme = .dark
        state.preferences = prefs
        state.preferences = UserPreferences.default
        #expect(state.preferences == UserPreferences.default)
    }

    @Test("Multiple preference changes")
    func multiplePreferenceChanges() {
        var state = SettingsDomainState()
        var prefs = state.preferences
        prefs.theme = .dark
        state.preferences = prefs

        var updatedPrefs = state.preferences
        updatedPrefs.theme = .light
        state.preferences = updatedPrefs

        #expect(state.preferences.theme == .light)
    }
}

@Suite("SettingsDomainState Loading States Tests")
struct SettingsDomainStateLoadingStatesTests {
    @Test("Can set isLoading flag")
    func setIsLoading() {
        var state = SettingsDomainState()
        state.isLoading = true
        #expect(state.isLoading)
    }

    @Test("Can set isSaving flag")
    func setIsSaving() {
        var state = SettingsDomainState()
        state.isSaving = true
        #expect(state.isSaving)
    }

    @Test("Loading and saving flags are independent")
    func loadingAndSavingIndependent() {
        var state = SettingsDomainState()
        state.isLoading = true
        state.isSaving = true
        #expect(state.isLoading)
        #expect(state.isSaving)

        state.isLoading = false
        #expect(!state.isLoading)
        #expect(state.isSaving)
    }

    @Test("Can toggle loading and saving flags")
    func toggleLoadingAndSaving() {
        var state = SettingsDomainState()
        state.isLoading = true
        state.isSaving = true
        #expect(state.isLoading && state.isSaving)

        state.isLoading = false
        state.isSaving = false
        #expect(!state.isLoading && !state.isSaving)
    }
}

@Suite("SettingsDomainState Error Tests")
struct SettingsDomainStateErrorTests {
    @Test("Can set error message")
    func setErrorMessage() {
        var state = SettingsDomainState()
        state.error = "Failed to save settings"
        #expect(state.error == "Failed to save settings")
    }

    @Test("Can clear error message")
    func clearErrorMessage() {
        var state = SettingsDomainState()
        state.error = "Error"
        state.error = nil
        #expect(state.error == nil)
    }

    @Test("Can change error message")
    func changeErrorMessage() {
        var state = SettingsDomainState()
        state.error = "Error 1"
        state.error = "Error 2"
        #expect(state.error == "Error 2")
    }
}

@Suite("SettingsDomainState Confirmation Dialog Tests")
struct SettingsDomainStateConfirmationDialogTests {
    @Test("Can show clear history confirmation")
    func testShowClearHistoryConfirmation() {
        var state = SettingsDomainState()
        state.showClearHistoryConfirmation = true
        #expect(state.showClearHistoryConfirmation)
    }

    @Test("Can hide clear history confirmation")
    func hideClearHistoryConfirmation() {
        var state = SettingsDomainState()
        state.showClearHistoryConfirmation = true
        state.showClearHistoryConfirmation = false
        #expect(!state.showClearHistoryConfirmation)
    }

    @Test("Can show sign out confirmation")
    func testShowSignOutConfirmation() {
        var state = SettingsDomainState()
        state.showSignOutConfirmation = true
        #expect(state.showSignOutConfirmation)
    }

    @Test("Can hide sign out confirmation")
    func hideSignOutConfirmation() {
        var state = SettingsDomainState()
        state.showSignOutConfirmation = true
        state.showSignOutConfirmation = false
        #expect(!state.showSignOutConfirmation)
    }

    @Test("Confirmation dialogs are independent")
    func confirmationDialogsIndependent() {
        var state = SettingsDomainState()
        state.showClearHistoryConfirmation = true
        state.showSignOutConfirmation = true
        #expect(state.showClearHistoryConfirmation)
        #expect(state.showSignOutConfirmation)

        state.showClearHistoryConfirmation = false
        #expect(!state.showClearHistoryConfirmation)
        #expect(state.showSignOutConfirmation)
    }

    @Test("Can toggle both confirmation dialogs")
    func toggleBothConfirmationDialogs() {
        var state = SettingsDomainState()
        state.showClearHistoryConfirmation = true
        state.showSignOutConfirmation = true
        #expect(state.showClearHistoryConfirmation && state.showSignOutConfirmation)

        state.showClearHistoryConfirmation = false
        state.showSignOutConfirmation = false
        #expect(!state.showClearHistoryConfirmation && !state.showSignOutConfirmation)
    }
}

@Suite("SettingsDomainState Muted Content Input Tests")
struct SettingsDomainStateMutedContentInputTests {
    @Test("Can set newMutedSource")
    func setNewMutedSource() {
        var state = SettingsDomainState()
        state.newMutedSource = "BBC News"
        #expect(state.newMutedSource == "BBC News")
    }

    @Test("Can clear newMutedSource")
    func clearNewMutedSource() {
        var state = SettingsDomainState()
        state.newMutedSource = "Source"
        state.newMutedSource = ""
        #expect(state.newMutedSource.isEmpty)
    }

    @Test("Can set newMutedKeyword")
    func setNewMutedKeyword() {
        var state = SettingsDomainState()
        state.newMutedKeyword = "politics"
        #expect(state.newMutedKeyword == "politics")
    }

    @Test("Can clear newMutedKeyword")
    func clearNewMutedKeyword() {
        var state = SettingsDomainState()
        state.newMutedKeyword = "keyword"
        state.newMutedKeyword = ""
        #expect(state.newMutedKeyword.isEmpty)
    }

    @Test("Muted inputs are independent")
    func mutedInputsIndependent() {
        var state = SettingsDomainState()
        state.newMutedSource = "Source"
        state.newMutedKeyword = "Keyword"
        #expect(state.newMutedSource == "Source")
        #expect(state.newMutedKeyword == "Keyword")
    }

    @Test("Can update both muted inputs separately")
    func updateBothMutedInputsSeparately() {
        var state = SettingsDomainState()
        state.newMutedSource = "Source1"
        #expect(state.newMutedSource == "Source1")
        #expect(state.newMutedKeyword.isEmpty)

        state.newMutedKeyword = "Keyword1"
        #expect(state.newMutedSource == "Source1")
        #expect(state.newMutedKeyword == "Keyword1")
    }

    @Test("Can clear individual muted inputs")
    func clearIndividualMutedInputs() {
        var state = SettingsDomainState()
        state.newMutedSource = "Source"
        state.newMutedKeyword = "Keyword"

        state.newMutedSource = ""
        #expect(state.newMutedSource.isEmpty)
        #expect(state.newMutedKeyword == "Keyword")
    }
}

@Suite("SettingsDomainState Equatable Tests")
struct SettingsDomainStateEquatableTests {
    @Test("Two initial states are equal")
    func twoInitialStatesEqual() {
        let state1 = SettingsDomainState()
        let state2 = SettingsDomainState()
        #expect(state1 == state2)
    }

    @Test("States with different preferences are not equal")
    func differentPreferencesNotEqual() {
        var state1 = SettingsDomainState()
        var state2 = SettingsDomainState()
        var prefs = UserPreferences.default
        prefs.theme = .dark
        state1.preferences = prefs
        #expect(state1 != state2)
    }

    @Test("States with different loading flags are not equal")
    func differentIsLoadingNotEqual() {
        var state1 = SettingsDomainState()
        var state2 = SettingsDomainState()
        state1.isLoading = true
        #expect(state1 != state2)
    }

    @Test("States with different saving flags are not equal")
    func differentIsSavingNotEqual() {
        var state1 = SettingsDomainState()
        var state2 = SettingsDomainState()
        state1.isSaving = true
        #expect(state1 != state2)
    }

    @Test("States with different confirmation dialogs are not equal")
    func differentConfirmationDialogsNotEqual() {
        var state1 = SettingsDomainState()
        var state2 = SettingsDomainState()
        state1.showClearHistoryConfirmation = true
        #expect(state1 != state2)
    }

    @Test("States with different muted inputs are not equal")
    func differentMutedInputsNotEqual() {
        var state1 = SettingsDomainState()
        var state2 = SettingsDomainState()
        state1.newMutedSource = "Source"
        #expect(state1 != state2)
    }

    @Test("States become equal after same mutations")
    func statesEqualAfterSameMutations() {
        var state1 = SettingsDomainState()
        var state2 = SettingsDomainState()
        var prefs = UserPreferences.default
        prefs.theme = .dark
        state1.preferences = prefs
        state2.preferences = prefs
        #expect(state1 == state2)
    }
}

@Suite("SettingsDomainState Complex Settings Scenarios")
struct SettingsDomainStateComplexSettingsScenarioTests {
    @Test("Simulate loading settings")
    func loadingSettings() {
        var state = SettingsDomainState()
        state.isLoading = true
        var prefs = UserPreferences.default
        prefs.theme = .dark
        state.preferences = prefs
        state.isLoading = false

        #expect(!state.isLoading)
        #expect(state.preferences.theme == .dark)
    }

    @Test("Simulate saving preferences")
    func savingPreferences() {
        var state = SettingsDomainState()
        var prefs = state.preferences
        prefs.theme = .dark
        state.preferences = prefs

        state.isSaving = true
        // Simulate save
        state.isSaving = false

        #expect(!state.isSaving)
        #expect(state.preferences.theme == .dark)
    }

    @Test("Simulate clear history confirmation workflow")
    func clearHistoryConfirmationWorkflow() {
        var state = SettingsDomainState()
        state.showClearHistoryConfirmation = true
        #expect(state.showClearHistoryConfirmation)

        state.showClearHistoryConfirmation = false
        #expect(!state.showClearHistoryConfirmation)
    }

    @Test("Simulate sign out confirmation workflow")
    func signOutConfirmationWorkflow() {
        var state = SettingsDomainState()
        state.showSignOutConfirmation = true
        #expect(state.showSignOutConfirmation)

        state.showSignOutConfirmation = false
        #expect(!state.showSignOutConfirmation)
    }

    @Test("Simulate adding muted content")
    func addingMutedContent() {
        var state = SettingsDomainState()
        state.newMutedSource = "BBC"
        state.isSaving = true
        // Simulate adding to muted sources list
        state.newMutedSource = ""
        state.isSaving = false

        #expect(state.newMutedSource.isEmpty)
        #expect(!state.isSaving)
    }

    @Test("Simulate multiple settings updates")
    func multipleSettingsUpdates() {
        var state = SettingsDomainState()
        state.isLoading = true

        var prefs = state.preferences
        prefs.theme = .dark
        state.preferences = prefs
        state.isLoading = false

        #expect(state.preferences.theme == .dark)

        state.newMutedSource = "Source"
        state.newMutedKeyword = "Keyword"
        #expect(state.newMutedSource == "Source")
        #expect(state.newMutedKeyword == "Keyword")

        state.isSaving = true
        state.newMutedSource = ""
        state.newMutedKeyword = ""
        state.isSaving = false

        #expect(state.newMutedSource.isEmpty)
        #expect(state.newMutedKeyword.isEmpty)
    }

    @Test("Simulate error saving settings")
    func errorSavingSettings() {
        var state = SettingsDomainState()
        state.isSaving = true
        state.error = "Failed to save settings"
        state.isSaving = false

        #expect(!state.isSaving)
        #expect(state.error == "Failed to save settings")
    }

    @Test("Simulate recovery from error")
    func recoveryFromError() {
        var state = SettingsDomainState()
        state.error = "Error occurred"
        #expect(state.error == "Error occurred")

        state.error = nil
        state.isSaving = true
        var prefs = state.preferences
        prefs.theme = .dark
        state.preferences = prefs
        state.isSaving = false

        #expect(state.error == nil)
        #expect(state.preferences.theme == .dark)
    }
}
