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
        articleID = article.id
        title = article.title
        articleDescription = article.description
        content = article.content
        author = article.author
        sourceName = article.source.name
        sourceID = article.source.id
        url = article.url
        imageURL = article.imageURL
        publishedAt = article.publishedAt
        savedAt = Date()
        category = article.category?.rawValue
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
        articleID = article.id
        title = article.title
        articleDescription = article.description
        sourceName = article.source.name
        sourceID = article.source.id
        url = article.url
        imageURL = article.imageURL
        publishedAt = article.publishedAt
        readAt = Date()
        category = article.category?.rawValue
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
