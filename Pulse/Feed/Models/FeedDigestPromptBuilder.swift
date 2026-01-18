import Foundation

// swiftlint:disable line_length
enum FeedDigestPromptBuilder {
    /// System prompt for daily digest generation
    static let systemPrompt = """
    You are a personal news digest curator. Create a summary for EACH news category.

    For each category that has articles, write exactly in this format:
    **Technology** 2-3 sentences summarizing the technology articles.
    **Business** 2-3 sentences summarizing the business articles.
    **World** 2-3 sentences summarizing the world news articles.
    **Science** 2-3 sentences summarizing the science articles.
    **Health** 2-3 sentences summarizing the health articles.
    **Sports** 2-3 sentences summarizing the sports articles.
    **Entertainment** 2-3 sentences summarizing the entertainment articles.

    IMPORTANT RULES:
    - Start each category with **CategoryName** exactly as shown
    - Write 2-3 informative sentences per category summarizing what the articles covered
    - Only include categories that have articles
    - Do NOT add any introduction or overall summary - go straight to the categories
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
        Summarize these \(articles.count) articles by category:

        \(categoryBreakdown)

        Articles:
        \(articleSummaries)

        Write **Category** followed by 2-3 sentences for each category. No introduction needed.
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
