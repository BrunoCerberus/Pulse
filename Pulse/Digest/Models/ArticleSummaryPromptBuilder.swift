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
        // All untrusted (RSS-sourced) fields pass through `PromptSanitizer`
        // before interpolation. See `PromptSanitizer` for the threat model.
        var content = "Title: \(PromptSanitizer.sanitize(article.title, maxLength: 200))\n"
        content += "Source: \(PromptSanitizer.sanitize(article.source.name, maxLength: 80))\n"

        if let description = article.description, !description.isEmpty {
            let cleaned = PromptSanitizer.sanitize(stripHTML(from: description), maxLength: 500)
            if !cleaned.isEmpty {
                content += "Description: \(cleaned)\n"
            }
        }

        if let articleContent = article.content, !articleContent.isEmpty {
            let cleaned = PromptSanitizer.sanitize(stripHTML(from: articleContent), maxLength: 1500)
            if !cleaned.isEmpty {
                content += "Content: \(cleaned)"
            }
        }

        return content
    }

    private static func stripHTML(from html: String) -> String {
        html.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
            .replacing("&nbsp;", with: " ")
            .replacing("&amp;", with: "&")
            .replacing("&lt;", with: "<")
            .replacing("&gt;", with: ">")
            .replacing("&quot;", with: "\"")
            .replacing("&#39;", with: "'")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
