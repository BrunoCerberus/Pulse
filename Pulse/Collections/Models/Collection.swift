import Foundation

enum CollectionType: String, Codable, CaseIterable {
    case featured
    case topic
    case user
    case aiCurated

    var displayName: String {
        switch self {
        case .featured: return "Featured"
        case .topic: return "Topic"
        case .user: return "My Collection"
        case .aiCurated: return "AI Curated"
        }
    }
}

struct Collection: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let imageURL: String?
    let articles: [Article]
    let articleCount: Int
    let readArticleIDs: Set<String>
    let collectionType: CollectionType
    let isPremium: Bool
    let createdAt: Date
    let updatedAt: Date

    var progress: Double {
        guard articleCount > 0 else { return 0 }
        return Double(readArticleIDs.count) / Double(articleCount)
    }

    var isCompleted: Bool {
        articleCount > 0 && readArticleIDs.count >= articleCount
    }

    var nextUnreadArticle: Article? {
        articles.first { !readArticleIDs.contains($0.id) }
    }

    static func == (lhs: Collection, rhs: Collection) -> Bool {
        lhs.id == rhs.id &&
            lhs.name == rhs.name &&
            lhs.description == rhs.description &&
            lhs.imageURL == rhs.imageURL &&
            lhs.articles == rhs.articles &&
            lhs.articleCount == rhs.articleCount &&
            lhs.readArticleIDs == rhs.readArticleIDs &&
            lhs.collectionType == rhs.collectionType &&
            lhs.isPremium == rhs.isPremium
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Collection {
    static func userCollection(
        id: String = UUID().uuidString,
        name: String,
        description: String = "",
        articles: [Article] = [],
        readArticleIDs: Set<String> = []
    ) -> Collection {
        Collection(
            id: id,
            name: name,
            description: description,
            imageURL: nil,
            articles: articles,
            articleCount: articles.count,
            readArticleIDs: readArticleIDs,
            collectionType: .user,
            isPremium: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func withArticle(_ article: Article) -> Collection {
        var updatedArticles = articles
        if !updatedArticles.contains(where: { $0.id == article.id }) {
            updatedArticles.append(article)
        }
        return Collection(
            id: id,
            name: name,
            description: description,
            imageURL: imageURL,
            articles: updatedArticles,
            articleCount: updatedArticles.count,
            readArticleIDs: readArticleIDs,
            collectionType: collectionType,
            isPremium: isPremium,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    func withoutArticle(_ articleID: String) -> Collection {
        let updatedArticles = articles.filter { $0.id != articleID }
        var updatedReadIDs = readArticleIDs
        updatedReadIDs.remove(articleID)
        return Collection(
            id: id,
            name: name,
            description: description,
            imageURL: imageURL,
            articles: updatedArticles,
            articleCount: updatedArticles.count,
            readArticleIDs: updatedReadIDs,
            collectionType: collectionType,
            isPremium: isPremium,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    func markingArticleAsRead(_ articleID: String) -> Collection {
        var updatedReadIDs = readArticleIDs
        updatedReadIDs.insert(articleID)
        return Collection(
            id: id,
            name: name,
            description: description,
            imageURL: imageURL,
            articles: articles,
            articleCount: articleCount,
            readArticleIDs: updatedReadIDs,
            collectionType: collectionType,
            isPremium: isPremium,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
