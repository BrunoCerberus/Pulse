import Foundation

enum FeedDigestPromptBuilder {
    /// System prompt for daily digest generation
    static let systemPrompt = """
    You are a personal news digest curator. Summarize articles by category.

    OUTPUT FORMAT (follow exactly):
    **Technology** Your 2-3 sentence summary of technology articles goes here.
    **Business** Your 2-3 sentence summary of business articles goes here.
    **World** Your 2-3 sentence summary of world news goes here.
    **Science** Your 2-3 sentence summary of science articles goes here.
    **Health** Your 2-3 sentence summary of health articles goes here.
    **Sports** Your 2-3 sentence summary of sports articles goes here.
    **Entertainment** Your 2-3 sentence summary of entertainment articles goes here.

    RULES:
    - Start each section with **CategoryName** in bold (double asterisks)
    - Write engaging, conversational summaries (2-3 sentences each)
    - Mention specific topics, companies, or events from the articles
    - Only include categories that have articles in the input
    - NO introductions, NO conclusions, NO meta-commentary
    - Start immediately with the first **Category**
    """

    /// Caps articles to a safe limit and returns the subset for digest generation
    /// - Parameter articles: Full list of articles from API
    /// - Returns: Capped list of most recent articles, safe for context window
    static func cappedArticles(from articles: [Article]) -> [Article] {
        let maxArticles = LLMConfiguration.maxArticlesForDigest
        guard articles.count > maxArticles else { return articles }

        // Take the most recent articles (assuming already sorted by recency)
        return Array(articles.prefix(maxArticles))
    }

    /// Builds the user message prompt from latest articles
    /// - Parameter articles: Articles to include (should be pre-capped via `cappedArticles`)
    static func buildPrompt(for articles: [Article]) -> String {
        let articleSummaries = articles.enumerated().map { index, article in
            buildArticleSummary(article, index: index + 1)
        }.joined(separator: "\n\n")

        let categoryBreakdown = buildCategoryBreakdown(articles)

        return """
        Here are the latest \(articles.count) news articles, organized by category:

        \(categoryBreakdown)

        Articles:
        \(articleSummaries)

        Now write a summary for each category. Start with **CategoryName** then your summary. Example:
        **Technology** The tech world buzzed with news about...

        Begin:
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
            summary += "\nSummary: \(String(clean.prefix(150)))"
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
