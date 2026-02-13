import Foundation

/// Builds prompts for on-device article summarization.
///
/// This builder creates prompts optimized for the on-device LLM model,
/// formatting article content for concise summary generation.
///
/// ## Prompt Structure
/// - System prompt defines summarization guidelines (2-3 sentences, facts only)
/// - User prompt contains article title, source, description, and truncated content
///
/// ## Content Processing
/// - HTML is stripped from description and content
/// - Content is truncated to 1500 characters to fit context window
enum ArticleSummaryPromptBuilder {
    /// System prompt for article summarization
    static let systemPrompt = """
    You are a concise news summarizer. Your task is to create a brief, informative summary of the article provided.
    Guidelines:
    - Write 2-3 sentences maximum
    - Focus on the key facts and main takeaway
    - Use clear, accessible language
    - Do not include opinions or commentary
    - Start directly with the summary, no preamble
    """

    /// Builds the user message prompt for summarization (without chat template markers)
    /// The LLM service will wrap this with the appropriate chat template
    static func buildPrompt(for article: Article) -> String {
        let articleContent = buildArticleContent(article)

        return """
        Summarize this article:

        \(articleContent)
        """
    }

    private static func buildArticleContent(_ article: Article) -> String {
        var content = "Title: \(article.title)\n"
        content += "Source: \(article.source.name)\n"

        if let description = article.description, !description.isEmpty {
            let cleanDescription = stripHTML(from: description)
            content += "Description: \(cleanDescription)\n"
        }

        if let articleContent = article.content, !articleContent.isEmpty {
            let cleanContent = stripHTML(from: articleContent)
            let truncated = String(cleanContent.prefix(1500))
            content += "Content: \(truncated)"
        }

        return content
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
