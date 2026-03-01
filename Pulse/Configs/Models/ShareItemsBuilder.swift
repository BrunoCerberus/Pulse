import Foundation

/// Builds formatted activity items for sharing articles via UIActivityViewController.
///
/// When both a `String` and `URL` are passed, iOS uses the string as share text
/// and the URL as the link attachment — social apps display both.
enum ShareItemsBuilder {
    /// Builds activity items for sharing an article.
    /// - Parameter article: The article to share.
    /// - Returns: An array containing formatted share text and the article URL.
    static func activityItems(for article: Article) -> [Any] {
        let text = "\(article.title) — \(article.source.name)"
        if let url = URL(string: article.url) {
            return [text, url]
        }
        return [text]
    }
}
