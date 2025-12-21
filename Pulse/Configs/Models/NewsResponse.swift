import Foundation

struct NewsResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [ArticleDTO]
}
