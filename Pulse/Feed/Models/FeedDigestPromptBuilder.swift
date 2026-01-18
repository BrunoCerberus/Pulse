import Foundation

// swiftlint:disable line_length
enum FeedDigestPromptBuilder {
    /// System prompt for daily digest generation
    static let systemPrompt = """
    You are a personal news digest curator. Create a daily summary.

    FORMAT:
    First, write 2-3 sentences giving an OVERALL summary of all the articles together - what themes connect them, what was interesting about today's reading as a whole.

    Then, for each category that has articles, write a short paragraph starting with the category name in bold like **Technology** or **Business**, followed by 1-2 sentences about those specific articles.

    Only include categories that have articles. Be specific about what the articles cover.
    """

    /// Caps articles to a safe limit and returns the subset for digest generation
    /// - Parameter articles: Full list of articles from reading history
    /// - Returns: Capped list of most recent articles, safe for context window
    static func cappedArticles(from articles: [Article]) -> [Article] {
        let maxArticles = LLMConfiguration.maxArticlesForDigest
        guard articles.count > maxArticles else { return articles }

        // Take the most recent articles (assuming already sorted by recency)
        return Array(articles.prefix(maxArticles))
    }

    /// Builds the user message prompt from reading history
    /// - Parameter articles: Articles to include (should be pre-capped via `cappedArticles`)
    static func buildPrompt(for articles: [Article]) -> String {
        let articleSummaries = articles.enumerated().map { index, article in
            buildArticleSummary(article, index: index + 1)
        }.joined(separator: "\n\n")

        let categoryBreakdown = buildCategoryBreakdown(articles)

        return """
        Create a daily digest from these \(articles.count) articles I read today:

        \(categoryBreakdown)

        Articles:
        \(articleSummaries)

        Generate a digest with [KEY INSIGHT] followed by a section for each category that has articles.
        """
    }

    /// Estimates the token count for a given set of articles
    /// Used to verify prompt will fit within context window
    static func estimatedTokenCount(for articles: [Article]) -> Int {
        let systemTokens = 100 // Approximate system prompt tokens
        let articleTokens = articles.count * LLMConfiguration.estimatedTokensPerArticle
        let overheadTokens = 50 // Prompt structure overhead
        return systemTokens + articleTokens + overheadTokens
    }

    private static func buildArticleSummary(_ article: Article, index: Int) -> String {
        var summary = "[\(index)] \(article.title)"
        summary += "\nSource: \(article.source.name)"

        if let category = article.category {
            summary += " | Category: \(category.displayName)"
        }

        if let description = article.description, !description.isEmpty {
            let clean = stripHTML(from: description)
            summary += "\nSummary: \(String(clean.prefix(200)))"
        }

        return summary
    }

    private static func buildCategoryBreakdown(_ articles: [Article]) -> String {
        let grouped = Dictionary(grouping: articles) { $0.category ?? .world }
        let breakdown = grouped.map { "\($0.key.displayName): \($0.value.count) articles" }
            .joined(separator: ", ")
        return "Topics covered: \(breakdown)"
    }

    private static func stripHTML(from html: String) -> String {
        html.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// swiftlint:enable line_length
