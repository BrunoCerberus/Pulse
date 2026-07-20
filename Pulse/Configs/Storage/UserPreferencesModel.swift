import Foundation
import SwiftData

/// SwiftData model for persisting user preferences locally.
///
/// Every property has a default value so the model is compatible with
/// CloudKit sync via `NSPersistentCloudKitContainer`.
@Model
final class UserPreferencesModel {
    /// News categories the user follows (stored as raw string values).
    var followedTopics: [String] = []
    /// News source identifiers the user has muted (hidden from feeds).
    var mutedSources: [String] = []
    /// Keywords to filter out from article titles and content.
    var mutedKeywords: [String] = []
    /// ISO 639-1 language code for preferred content language.
    var preferredLanguage: String = "en"
    /// Whether push notifications are enabled for this user.
    var notificationsEnabled: Bool = false
    /// Whether breaking news alerts are enabled (requires notificationsEnabled).
    var breakingNewsNotifications: Bool = false
    /// Whether the scheduled daily audio briefing notification is enabled.
    var morningBriefingEnabled: Bool = false
    /// Hour (0-23) at which the daily briefing notification fires.
    var morningBriefingHour: Int = 7
    /// Minute (0-59) at which the daily briefing notification fires.
    var morningBriefingMinute: Int = 0
    /// Number of For You articles included in the briefing, after the digest.
    var morningBriefingArticleCount: Int = 10

    /// Creates a persistence model from domain preferences.
    /// - Parameter preferences: The domain preferences to persist.
    init(from preferences: UserPreferences) {
        followedTopics = preferences.followedTopics.map(\.rawValue)
        mutedSources = preferences.mutedSources
        mutedKeywords = preferences.mutedKeywords
        preferredLanguage = preferences.preferredLanguage
        notificationsEnabled = preferences.notificationsEnabled
        breakingNewsNotifications = preferences.breakingNewsNotifications
        morningBriefingEnabled = preferences.morningBriefingEnabled
        morningBriefingHour = preferences.morningBriefingHour
        morningBriefingMinute = preferences.morningBriefingMinute
        morningBriefingArticleCount = preferences.morningBriefingArticleCount
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
            breakingNewsNotifications: breakingNewsNotifications,
            morningBriefingEnabled: morningBriefingEnabled,
            morningBriefingHour: morningBriefingHour,
            morningBriefingMinute: morningBriefingMinute,
            morningBriefingArticleCount: morningBriefingArticleCount,
        )
    }
}
