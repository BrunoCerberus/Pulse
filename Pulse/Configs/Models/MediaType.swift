import EntropyCore
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
            AppLocalization.localized("media.type.videos")
        case .podcast:
            AppLocalization.localized("media.type.podcasts")
        }
    }

    /// SF Symbol icon for the media type.
    var icon: String {
        switch self {
        case .video:
            "play.rectangle.fill"
        case .podcast:
            "headphones"
        }
    }

    /// Accent color for the media type.
    var color: Color {
        switch self {
        case .video:
            .red // YouTube brand recognition
        case .podcast:
            Color.Accent.secondary
        }
    }

    /// Category slug used in Supabase API queries.
    var categorySlug: String {
        switch self {
        case .video:
            "videos"
        case .podcast:
            "podcasts"
        }
    }

    /// Creates a MediaType from a raw string value (case-insensitive).
    init?(fromString value: String?) {
        guard let value else { return nil }
        self.init(rawValue: value.lowercased())
    }
}
