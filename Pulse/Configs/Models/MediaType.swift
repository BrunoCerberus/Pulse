import SwiftUI

/// Type of media content for articles.
///
/// Used to distinguish between regular articles and media content (videos, podcasts)
/// fetched from the Supabase backend.
enum MediaType: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case video
    case podcast

    var id: String {
        rawValue
    }

    /// Human-readable display name for the media type.
    var displayName: String {
        switch self {
        case .video:
            return String(localized: "media.type.videos")
        case .podcast:
            return String(localized: "media.type.podcasts")
        }
    }

    /// SF Symbol icon for the media type.
    var icon: String {
        switch self {
        case .video:
            return "play.rectangle.fill"
        case .podcast:
            return "headphones"
        }
    }

    /// Accent color for the media type.
    var color: Color {
        switch self {
        case .video:
            return .red // YouTube brand recognition
        case .podcast:
            return Color.Accent.secondary
        }
    }

    /// Category slug used in Supabase API queries.
    var categorySlug: String {
        switch self {
        case .video:
            return "videos"
        case .podcast:
            return "podcasts"
        }
    }

    /// Creates a MediaType from a raw string value (case-insensitive).
    init?(fromString value: String?) {
        guard let value else { return nil }
        self.init(rawValue: value.lowercased())
    }
}
