import Foundation

enum FeedDigestPromptBuilder {
    /// System prompt for daily digest generation
    static let systemPrompt = """
    You write casual, punchy news digests like a well-informed friend catching someone up over coffee. \
    Group by category using **CategoryName** as a header. \
    2-3 sentences per category — name real people, companies, and numbers. \
    Skip categories with no articles. No intro, no sign-off. Start with the first **Category** immediately.
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
        let grouped = Dictionary(grouping: articles) { $0.category ?? .world }
        let categoryNames = grouped.sorted { $0.value.count > $1.value.count }
            .map { $0.key.displayName }

        let articleList = articles.enumerated().map { index, article in
            let cat = article.category?.displayName ?? "World"
            var line = "\(index + 1). \(article.title) (\(article.source.name), \(cat))"
            if let desc = article.description, !desc.isEmpty {
                line += " — \(String(stripHTML(from: desc).prefix(250)))"
            }
            return line
        }.joined(separator: "\n")

        return """
        Articles:
        \(articleList)

        Write a digest with these categories: \(categoryNames.joined(separator: ", ")). \
        Use **CategoryName** before each section, like this:

        **Technology** Apple announced a new chip today, pushing performance 40% higher. Meanwhile, OpenAI rolled out...

        **Business** Markets rallied after the Fed signaled a pause on rate hikes...

        Now write the digest:
        """
    }

    /// Estimates the token count for a given set of articles
    /// Used to verify prompt will fit within context window
    static func estimatedTokenCount(for articles: [Article]) -> Int {
        let systemTokens = 60 // Compact system prompt tokens
        let articleTokens = articles.count * LLMConfiguration.estimatedTokensPerArticle
        let overheadTokens = 30 // Prompt structure overhead
        return systemTokens + articleTokens + overheadTokens
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
