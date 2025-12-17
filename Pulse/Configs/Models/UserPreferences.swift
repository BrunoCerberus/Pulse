import Foundation

struct UserPreferences: Equatable, Codable {
    var followedTopics: [NewsCategory]
    var followedSources: [String]
    var mutedSources: [String]
    var mutedKeywords: [String]
    var preferredLanguage: String
    var notificationsEnabled: Bool
    var breakingNewsNotifications: Bool

    static var `default`: UserPreferences {
        UserPreferences(
            followedTopics: [],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: Locale.current.language.languageCode?.identifier ?? "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true
        )
    }
}
