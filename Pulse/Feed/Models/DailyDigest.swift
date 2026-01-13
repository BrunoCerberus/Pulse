import Foundation

/// Represents a daily AI-generated digest of articles the user has read
struct DailyDigest: Equatable, Identifiable {
    let id: String
    let summary: String
    let sourceArticles: [Article]
    let generatedAt: Date

    var formattedDate: String {
        Self.dateFormatter.string(from: generatedAt)
    }

    var articleCount: Int {
        sourceArticles.count
    }

    var categoryBreakdown: [NewsCategory: Int] {
        Dictionary(grouping: sourceArticles.compactMap(\.category)) { $0 }
            .mapValues(\.count)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
}
