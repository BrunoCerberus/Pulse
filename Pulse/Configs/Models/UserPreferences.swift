import Foundation

struct UserPreferences: Equatable, Codable {
    var followedTopics: [NewsCategory]
    var mutedSources: [String]
    var mutedKeywords: [String]
    var preferredLanguage: String
    var notificationsEnabled: Bool
    var breakingNewsNotifications: Bool
    var morningBriefingEnabled: Bool = false
    var morningBriefingHour: Int = 7
    var morningBriefingMinute: Int = 0
    var morningBriefingArticleCount: Int = 10

    static var `default`: UserPreferences {
        UserPreferences(
            followedTopics: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: Locale.current.language.languageCode?.identifier ?? "en",
            notificationsEnabled: true,
            breakingNewsNotifications: true,
            morningBriefingEnabled: false,
            morningBriefingHour: 7,
            morningBriefingMinute: 0,
            morningBriefingArticleCount: 10,
        )
    }
}
