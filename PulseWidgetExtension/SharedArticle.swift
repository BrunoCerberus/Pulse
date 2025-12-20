import Foundation

/// Lightweight article model for widget data transfer
/// Must match SharedWidgetArticle in main app
struct SharedArticle: Codable, Identifiable {
    let id: String
    let title: String
    let source: String?

    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }
}
