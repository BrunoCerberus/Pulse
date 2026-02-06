import Foundation

enum FeedDigestPromptBuilder {
    /// System prompt for daily digest generation
    static let systemPrompt = """
    You are a news digest writer. \
    Summarize the articles below into flowing paragraphs — DO NOT list individual articles. \
    Use **CategoryName** as a header before each category. \
    Write exactly 2-3 sentences per category. Keep it short. Cover ALL categories equally. \
    Do NOT repeat yourself. Name key people, companies, and numbers. \
    Never repeat article titles or sources verbatim. No bullet points. No intro or sign-off.
    """

    /// Caps articles to a safe limit with balanced category coverage
    /// - Parameter articles: Full list of articles from API (sorted by recency)
    /// - Returns: Capped list ensuring each category gets fair representation
    static func cappedArticles(from articles: [Article]) -> [Article] {
        let maxTotal = LLMConfiguration.maxArticlesForDigest
        let maxPerCategory = LLMConfiguration.maxArticlesPerCategory
        guard articles.count > maxTotal else { return articles }

        // Take top N from each category for balanced coverage
        var grouped = Dictionary(grouping: articles) { $0.category ?? .world }
        var selected: [Article] = []
        for (_, categoryArticles) in grouped {
            // Articles are already sorted by recency globally;
            // preserve that order within each category
            selected.append(contentsOf: categoryArticles.prefix(maxPerCategory))
        }

        // If we still have room, fill with remaining most-recent articles
        if selected.count < maxTotal {
            let selectedIds = Set(selected.map(\.id))
            let remaining = articles.filter { !selectedIds.contains($0.id) }
            selected.append(contentsOf: remaining.prefix(maxTotal - selected.count))
        }

        // Final cap and sort by recency for prompt coherence
        return Array(selected.prefix(maxTotal).sorted { $0.publishedAt > $1.publishedAt })
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
                line += " — \(String(stripHTML(from: desc).prefix(150)))"
            }
            return line
        }.joined(separator: "\n")

        return """
        Articles:
        \(articleList)

        Summarize into flowing paragraphs for: \(categoryNames.joined(separator: ", ")). \
        Do NOT list articles. Write prose. Use **CategoryName** headers. \
        Keep each category to 2-3 sentences. Cover ALL categories. Example:

        **Technology** Apple's M5 chip delivers 40% faster performance, a meaningful upgrade for Pro users. \
        Meanwhile, the EU finalized its AI Act enforcement timeline with steep fines starting in March.

        **Business** Amazon shares dropped 8% amid concerns over its massive AI spending plans. \
        Canada unveiled a new auto industry strategy aimed at competing with Chinese EV manufacturers.

        Now write the digest for ALL categories (2-3 sentences each, no bullet points):
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
