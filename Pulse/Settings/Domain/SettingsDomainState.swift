import Foundation

struct SettingsDomainState: Equatable {
    var preferences: UserPreferences
    var isLoading: Bool
    var isSaving: Bool
    var error: String?
    var showClearHistoryConfirmation: Bool
    var showSignOutConfirmation: Bool
    var newMutedSource: String
    var newMutedKeyword: String

    static var initial: SettingsDomainState {
        SettingsDomainState(
            preferences: .default,
            isLoading: false,
            isSaving: false,
            error: nil,
            showClearHistoryConfirmation: false,
            showSignOutConfirmation: false,
            newMutedSource: "",
            newMutedKeyword: ""
        )
    }
}
