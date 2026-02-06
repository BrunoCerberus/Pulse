import Foundation

enum FeedDigestPromptBuilder {
    /// System prompt for daily digest generation
    static let systemPrompt = """
    You write casual, info-packed news digests like a well-informed friend catching someone up. \
    Group by category using **CategoryName** as a header. \
    Write 4-6 sentences per category — cover every key story, name real people, companies, and numbers. \
    Connect related stories when possible. \
    Skip categories with no articles. No intro, no sign-off. Start with the first **Category** immediately.
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

        Write a digest covering: \(categoryNames.joined(separator: ", ")). \
        Use **CategoryName** before each section. Cover every major story. Example:

        **Technology** Apple dropped its M5 chip with 40% faster performance — a big deal for Pro users. \
        OpenAI rolled out GPT-5 with real-time reasoning, and Google fired back with Gemini 2.5 hitting the App Store. \
        Meanwhile, the EU finalized its AI Act enforcement rules, giving companies until March to comply.

        Now write the full digest:
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
