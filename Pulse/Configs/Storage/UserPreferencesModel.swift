import Foundation
import SwiftData

@Model
final class UserPreferencesModel {
    var followedTopics: [String]
    var followedSources: [String]
    var mutedSources: [String]
    var mutedKeywords: [String]
    var preferredLanguage: String
    var notificationsEnabled: Bool
    var breakingNewsNotifications: Bool

    init(from preferences: UserPreferences) {
        followedTopics = preferences.followedTopics.map { $0.rawValue }
        followedSources = preferences.followedSources
        mutedSources = preferences.mutedSources
        mutedKeywords = preferences.mutedKeywords
        preferredLanguage = preferences.preferredLanguage
        notificationsEnabled = preferences.notificationsEnabled
        breakingNewsNotifications = preferences.breakingNewsNotifications
    }

    func toPreferences() -> UserPreferences {
        UserPreferences(
            followedTopics: followedTopics.compactMap { NewsCategory(rawValue: $0) },
            followedSources: followedSources,
            mutedSources: mutedSources,
            mutedKeywords: mutedKeywords,
            preferredLanguage: preferredLanguage,
            notificationsEnabled: notificationsEnabled,
            breakingNewsNotifications: breakingNewsNotifications
        )
    }
}
