import Foundation

/// Content source for generating AI digest
enum DigestSource: String, CaseIterable, Identifiable, Equatable, Sendable {
    case bookmarks
    case readingHistory
    case freshNews

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bookmarks:
            return String(localized: "digest.source.bookmarks")
        case .readingHistory:
            return String(localized: "digest.source.reading_history")
        case .freshNews:
            return String(localized: "digest.source.fresh_news")
        }
    }

    var icon: String {
        switch self {
        case .bookmarks:
            return "bookmark.fill"
        case .readingHistory:
            return "clock.fill"
        case .freshNews:
            return "newspaper.fill"
        }
    }

    var description: String {
        switch self {
        case .bookmarks:
            return String(localized: "digest.source.bookmarks.description")
        case .readingHistory:
            return String(localized: "digest.source.reading_history.description")
        case .freshNews:
            return String(localized: "digest.source.fresh_news.description")
        }
    }
}
