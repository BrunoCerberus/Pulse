import Foundation

/// Represents the available content languages for news articles.
///
/// Used by the backend's `language` column to filter articles by language.
/// The raw value matches the ISO 639-1 language code stored in Supabase.
enum ContentLanguage: String, CaseIterable, Codable, Equatable {
    case english = "en"
    case portuguese = "pt"
    case spanish = "es"

    /// Localized display name for the language picker.
    var displayName: String {
        switch self {
        case .english:
            return AppLocalization.shared.localized("language.english")
        case .portuguese:
            return AppLocalization.shared.localized("language.portuguese")
        case .spanish:
            return AppLocalization.shared.localized("language.spanish")
        }
    }

    /// Emoji flag for visual identification in the language picker.
    var flag: String {
        switch self {
        case .english:
            return "🇺🇸"
        case .portuguese:
            return "🇧🇷"
        case .spanish:
            return "🇪🇸"
        }
    }
}
