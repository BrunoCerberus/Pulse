import Foundation

enum ArticleSummaryPromptBuilder {
    static func buildPrompt(for article: Article) -> String {
        let systemPrompt = """
        You are a concise news summarizer. Your task is to create a brief, informative summary of the article provided.
        Guidelines:
        - Write 2-3 sentences maximum
        - Focus on the key facts and main takeaway
        - Use clear, accessible language
        - Do not include opinions or commentary
        - Start directly with the summary, no preamble
        """

        let articleContent = buildArticleContent(article)

        return """
        <|system|>
        \(systemPrompt)
        <|user|>
        Summarize this article:

        \(articleContent)
        <|assistant|>
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
