import Foundation

/// Lightweight article model for widget data transfer
/// Must match SharedWidgetArticle in main app
struct SharedArticle: Codable, Identifiable {
    let id: String
    let title: String
    let source: String?
    let imageURL: String?

    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }
}

/// Article with downloaded image data for widget display
struct WidgetArticle: Identifiable {
    let id: String
    let title: String
    let source: String?
    let imageData: Data?

    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }
}
