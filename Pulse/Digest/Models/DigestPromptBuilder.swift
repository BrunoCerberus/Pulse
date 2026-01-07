import Foundation

/// Builds prompts for the LLM to generate news digests
enum DigestPromptBuilder {
    /// Build a prompt for digest generation
    static func buildPrompt(for articles: [Article], source: DigestSource) -> String {
        let articlesText = formatArticles(articles)
        let sourceContext = sourceContextText(for: source)

        return """
        You are a helpful news digest assistant. Create a personalized news digest \
        based on the following articles. \(sourceContext)

        Format your response as a well-structured digest with:
        1. A brief overview (2-3 sentences summarizing the main themes)
        2. Key headlines with 1-2 sentence summaries for each major story
        3. Trends or patterns you notice across the articles
        4. A closing thought or recommendation

        Keep the tone informative but conversational. Be concise but thorough.

        Articles to summarize:

        \(articlesText)

        Generate the digest now:
        """
    }

    private static func formatArticles(_ articles: [Article]) -> String {
        articles.enumerated().map { index, article in
            """
            ---
            Article \(index + 1):
            Title: \(article.title)
            Source: \(article.source.name)
            Category: \(article.category?.displayName ?? "General")
            Published: \(formatDate(article.publishedAt))
            Summary: \(article.description ?? "No summary available")
            \(article.content.map { "Content: \($0)" } ?? "")
            ---
            """
        }.joined(separator: "\n\n")
    }

    private static func sourceContextText(for source: DigestSource) -> String {
        switch source {
        case .bookmarks:
            return "These are articles the user has saved as bookmarks - " +
                "focus on helping them catch up on their saved content."
        case .readingHistory:
            return "These are articles the user has recently read - " +
                "identify patterns in their interests and provide insights."
        case .freshNews:
            return "These are the latest news articles from topics the user follows - " +
                "prioritize timeliness and relevance."
        }
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
