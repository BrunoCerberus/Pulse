import Foundation

struct GuardianResponse: Codable {
    let response: GuardianResponseContent
}

struct GuardianResponseContent: Codable {
    let status: String
    let total: Int
    let startIndex: Int
    let pageSize: Int
    let currentPage: Int
    let pages: Int
    let results: [GuardianArticleDTO]
}

struct GuardianArticleDTO: Codable {
    let id: String
    let type: String
    let sectionId: String
    let sectionName: String
    let webPublicationDate: String
    let webTitle: String
    let webUrl: String
    let apiUrl: String
    let fields: GuardianFieldsDTO?

    func toArticle(category: NewsCategory? = nil) -> Article? {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var publishedDate = dateFormatter.date(from: webPublicationDate)
        if publishedDate == nil {
            dateFormatter.formatOptions = [.withInternetDateTime]
            publishedDate = dateFormatter.date(from: webPublicationDate)
        }

        guard let date = publishedDate else { return nil }

        let resolvedCategory = category ?? NewsCategory.fromGuardianSection(sectionId)

        return Article(
            id: id,
            title: webTitle,
            description: fields?.trailText,
            content: fields?.body,
            author: fields?.byline,
            source: ArticleSource(id: "guardian", name: sectionName),
            url: webUrl,
            imageURL: fields?.thumbnail,
            publishedAt: date,
            category: resolvedCategory
        )
    }
}

struct GuardianFieldsDTO: Codable {
    let thumbnail: String?
    let trailText: String?
    let body: String?
    let byline: String?
}
