import Foundation

/// Result of AI digest generation
struct DigestResult: Equatable, Identifiable, Sendable {
    let id: UUID
    let source: DigestSource
    let content: String
    let articleCount: Int
    let generatedAt: Date
    let articlesUsed: [Article]

    init(
        id: UUID = UUID(),
        source: DigestSource,
        content: String,
        articleCount: Int,
        generatedAt: Date = Date(),
        articlesUsed: [Article]
    ) {
        self.id = id
        self.source = source
        self.content = content
        self.articleCount = articleCount
        self.generatedAt = generatedAt
        self.articlesUsed = articlesUsed
    }
}
