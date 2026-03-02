import Foundation

/// Represents the domain state for the Settings feature.
///
/// This state is owned by `SettingsDomainInteractor` and published via `statePublisher`.
/// Settings include followed topics, notification preferences, theme, muted content,
/// and account actions (sign out).
struct SettingsDomainState: Equatable {
    /// Current user preferences.
    var preferences: UserPreferences

    /// Indicates whether preferences are being loaded.
    var isLoading: Bool

    /// Indicates whether preferences are being saved.
    var isSaving: Bool

    /// Error message to display, if any.
    var error: String?

    /// Whether to show the sign out confirmation dialog.
    var showSignOutConfirmation: Bool

    /// Text field content for adding a new muted source.
    var newMutedSource: String

    /// Text field content for adding a new muted keyword.
    var newMutedKeyword: String

    /// Whether to show the notification permission denied alert.
    var showNotificationsDeniedAlert: Bool

    /// Creates the default initial state.
    static var initial: SettingsDomainState {
        SettingsDomainState(
            preferences: .default,
            isLoading: false,
            isSaving: false,
            error: nil,
            showSignOutConfirmation: false,
            newMutedSource: "",
            newMutedKeyword: "",
            showNotificationsDeniedAlert: false
        )
    }
}
