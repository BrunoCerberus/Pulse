import Foundation
import SwiftData

@Model
final class BookmarkedArticle {
    @Attribute(.unique) var articleID: String
    var title: String
    var articleDescription: String?
    var content: String?
    var author: String?
    var sourceName: String
    var sourceID: String?
    var url: String
    var imageURL: String?
    var publishedAt: Date
    var savedAt: Date
    var category: String?

    init(from article: Article) {
        self.articleID = article.id
        self.title = article.title
        self.articleDescription = article.description
        self.content = article.content
        self.author = article.author
        self.sourceName = article.source.name
        self.sourceID = article.source.id
        self.url = article.url
        self.imageURL = article.imageURL
        self.publishedAt = article.publishedAt
        self.savedAt = Date()
        self.category = article.category?.rawValue
    }

    func toArticle() -> Article {
        Article(
            id: articleID,
            title: title,
            description: articleDescription,
            content: content,
            author: author,
            source: ArticleSource(id: sourceID, name: sourceName),
            url: url,
            imageURL: imageURL,
            publishedAt: publishedAt,
            category: category.flatMap { NewsCategory(rawValue: $0) }
        )
    }
}

@Model
final class ReadingHistoryEntry {
    @Attribute(.unique) var articleID: String
    var title: String
    var articleDescription: String?
    var sourceName: String
    var sourceID: String?
    var url: String
    var imageURL: String?
    var publishedAt: Date
    var readAt: Date
    var category: String?

    init(from article: Article) {
        self.articleID = article.id
        self.title = article.title
        self.articleDescription = article.description
        self.sourceName = article.source.name
        self.sourceID = article.source.id
        self.url = article.url
        self.imageURL = article.imageURL
        self.publishedAt = article.publishedAt
        self.readAt = Date()
        self.category = article.category?.rawValue
    }

    func toArticle() -> Article {
        Article(
            id: articleID,
            title: title,
            description: articleDescription,
            content: nil,
            author: nil,
            source: ArticleSource(id: sourceID, name: sourceName),
            url: url,
            imageURL: imageURL,
            publishedAt: publishedAt,
            category: category.flatMap { NewsCategory(rawValue: $0) }
        )
    }
}

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
        self.followedTopics = preferences.followedTopics.map { $0.rawValue }
        self.followedSources = preferences.followedSources
        self.mutedSources = preferences.mutedSources
        self.mutedKeywords = preferences.mutedKeywords
        self.preferredLanguage = preferences.preferredLanguage
        self.notificationsEnabled = preferences.notificationsEnabled
        self.breakingNewsNotifications = preferences.breakingNewsNotifications
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
