import Foundation

struct SettingsDomainState: Equatable {
    var preferences: UserPreferences
    var isLoading: Bool
    var isSaving: Bool
    var error: String?
    var showClearHistoryConfirmation: Bool

    static var initial: SettingsDomainState {
        SettingsDomainState(
            preferences: .default,
            isLoading: false,
            isSaving: false,
            error: nil,
            showClearHistoryConfirmation: false
        )
    }
}
