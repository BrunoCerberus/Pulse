import Foundation
import SwiftData

/// SwiftData model for persisting user preferences locally.
///
/// This model stores user settings including followed topics, muted content,
/// and notification preferences. Raw string values are used for enums to ensure
/// SwiftData compatibility while maintaining type safety through conversion methods.
@Model
final class UserPreferencesModel {
    /// News categories the user follows (stored as raw string values).
    var followedTopics: [String]
    /// News source identifiers the user has muted (hidden from feeds).
    var mutedSources: [String]
    /// Keywords to filter out from article titles and content.
    var mutedKeywords: [String]
    /// ISO 639-1 language code for preferred content language.
    var preferredLanguage: String
    /// Whether push notifications are enabled for this user.
    var notificationsEnabled: Bool
    /// Whether breaking news alerts are enabled (requires notificationsEnabled).
    var breakingNewsNotifications: Bool

    /// Creates a persistence model from domain preferences.
    /// - Parameter preferences: The domain preferences to persist.
    init(from preferences: UserPreferences) {
        followedTopics = preferences.followedTopics.map { $0.rawValue }
        mutedSources = preferences.mutedSources
        mutedKeywords = preferences.mutedKeywords
        preferredLanguage = preferences.preferredLanguage
        notificationsEnabled = preferences.notificationsEnabled
        breakingNewsNotifications = preferences.breakingNewsNotifications
    }

    /// Converts this persisted model back to domain preferences.
    /// - Returns: A UserPreferences instance with type-safe enum values.
    func toPreferences() -> UserPreferences {
        UserPreferences(
            followedTopics: followedTopics.compactMap { NewsCategory(rawValue: $0) },
            mutedSources: mutedSources,
            mutedKeywords: mutedKeywords,
            preferredLanguage: preferredLanguage,
            notificationsEnabled: notificationsEnabled,
            breakingNewsNotifications: breakingNewsNotifications
        )
    }
}
