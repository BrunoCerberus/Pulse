import Foundation

/// Builds prompts for on-device daily digest generation.
///
/// This builder creates prompts optimized for the on-device LLM model,
/// formatting multiple news articles into a structured daily digest.
///
/// ## Key Features
/// - **Balanced Category Coverage**: `cappedArticles` ensures each category gets fair representation
/// - **Token-Safe**: Respects `LLMConfiguration` context limits
/// - **Structured Output**: Prompts model to write separate paragraphs per category
///
/// ## Prompt Structure
/// - System prompt defines digest format (category headers, sentence limits)
/// - User prompt lists articles with titles, sources, and truncated descriptions
/// - Includes examples to guide model output format
///
/// ## Usage
/// ```swift
/// let capped = FeedDigestPromptBuilder.cappedArticles(from: articles)
/// let prompt = FeedDigestPromptBuilder.buildPrompt(for: capped)
/// ```
enum FeedDigestPromptBuilder {
    /// System prompt for daily digest generation
    static let systemPrompt = """
    You are a news digest writer. Write a SEPARATE paragraph for each category. \
    Every paragraph MUST start with **CategoryName** in bold. \
    Write exactly 2-3 sentences per category. Each category is its own self-contained paragraph. \
    Do NOT mix categories together. Do NOT mention other categories within a paragraph. \
    Name key people, companies, and numbers. No bullet points. No intro or sign-off.
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

        let categoryHeaders = categoryNames.map { "**\($0)**" }.joined(separator: ", ")

        return """
        Articles:
         \(articleList)

         Write one separate paragraph for each: \(categoryHeaders). \
         Each paragraph starts with its **CategoryName** header. Do NOT mix categories. Example:

         **Technology** Apple's M5 chip delivers 40% faster performance for Pro users.
         The EU finalized its AI Act enforcement timeline with steep fines starting in March.

         **Business** Amazon shares dropped 8% amid concerns over AI spending.
         Canada unveiled a new auto strategy aimed at competing with Chinese EV manufacturers.

         **Sports** The NBA trade deadline saw major moves, with several All-Stars changing teams.
         Meanwhile, the Super Bowl preparations are underway in New Orleans.

         Now write one paragraph per category (\(categoryHeaders)), 2-3 sentences each:
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
