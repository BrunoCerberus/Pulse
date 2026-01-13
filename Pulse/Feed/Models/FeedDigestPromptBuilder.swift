import Foundation

enum FeedDigestPromptBuilder {
    /// System prompt for daily digest generation
    static let systemPrompt = """
    You are a personal news digest curator. Your task is to create a cohesive daily summary of articles the user has read.

    Guidelines:
    - Write a flowing narrative summary, not bullet points
    - Group related topics together naturally
    - Highlight key themes and connections between articles
    - Keep the tone informative but conversational
    - Maximum 3-4 paragraphs
    - Start directly with the summary, no greeting or preamble
    - End with a brief insight or observation about the day's reading
    """

    /// Builds the user message prompt from reading history
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

        Generate a cohesive summary highlighting the main themes and insights.
        """
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
