import Foundation

/// Manages in-app localization based on the user's Content Language preference.
///
/// Unlike `String(localized:)` which follows the iOS system locale,
/// `AppLocalization` loads strings from the `.lproj` bundle matching
/// the user's in-app `ContentLanguage` selection. This ensures that
/// UI labels (tabs, categories, buttons) update when the user switches
/// Content Language in Settings — not just article content.
///
/// Usage:
/// ```swift
/// // Instead of String(localized: "home.title")
/// AppLocalization.shared.localized("home.title")
/// ```
@MainActor
final class AppLocalization: ObservableObject {
    static let shared = AppLocalization()

    /// The current language code (e.g. "en", "pt", "es").
    /// Drives SwiftUI reactivity via `@Published`.
    @Published private(set) var language: String = "en" {
        didSet { _languageStorage = language }
    }

    /// Thread-safe copy of `language` for `nonisolated` access from `localized(_:)`.
    private nonisolated(unsafe) var _languageStorage: String = "en"

    /// Locale matching the current language, for `.environment(\.locale, ...)`.
    var locale: Locale {
        Locale(identifier: language)
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "pulse.preferredLanguage")
        let initial = saved ?? (Locale.current.language.languageCode?.identifier ?? "en")
        language = initial
        _languageStorage = initial
    }

    /// Updates the current language and persists it to UserDefaults.
    ///
    /// Called by `SettingsDomainInteractor.changeLanguage()` when the user
    /// switches Content Language, and by `PulseSceneDelegate` on app launch
    /// to sync from SwiftData.
    func updateLanguage(_ code: String) {
        guard language != code else { return }
        language = code
        UserDefaults.standard.set(code, forKey: "pulse.preferredLanguage")
    }

    /// Returns the localized string for `key` from the current language bundle.
    ///
    /// This method is `nonisolated` so it can be called from any context
    /// (e.g. `LocalizedError.errorDescription`). Bundle lookup is thread-safe.
    nonisolated func localized(_ key: String) -> String {
        let lang = _languageStorage
        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
