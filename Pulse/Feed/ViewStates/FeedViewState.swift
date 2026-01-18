import Foundation

// MARK: - Processing Phase

enum AIProcessingPhase: Equatable {
    case generating

    var progress: Double {
        1.0
    }

    var isGenerating: Bool {
        true
    }
}

// MARK: - Display State

enum FeedDisplayState: Equatable {
    case idle
    case loading
    case processing(phase: AIProcessingPhase)
    case completed
    case empty
    case error
}

// MARK: - View State

struct FeedViewState: Equatable {
    var displayState: FeedDisplayState
    var headerDate: String
    var streamingText: String
    var digest: DigestViewItem?
    var sourceArticles: [FeedSourceArticle]
    var errorMessage: String?
    var selectedArticle: Article?

    static var initial: FeedViewState {
        FeedViewState(
            displayState: .loading,
            headerDate: "",
            streamingText: "",
            digest: nil,
            sourceArticles: [],
            errorMessage: nil,
            selectedArticle: nil
        )
    }
}

// MARK: - View Items

struct DigestViewItem: Equatable, Identifiable {
    let id: String
    let summary: String
    let articleCount: Int
    let generatedAt: String

    init(from digest: DailyDigest) {
        id = digest.id
        summary = digest.summary
        articleCount = digest.articleCount
        generatedAt = digest.formattedDate
    }
}

struct FeedSourceArticle: Identifiable, Equatable {
    let id: String
    let title: String
    let source: String
    let category: String?
    let categoryType: NewsCategory?
    let imageURL: String?
    let article: Article

    init(from article: Article) {
        id = article.id
        title = article.title
        source = article.source.name
        category = article.category?.displayName
        categoryType = article.category
        imageURL = article.imageURL
        self.article = article
    }
}

// MARK: - Digest Section

struct DigestSection: Identifiable, Equatable {
    let id: String
    let title: String
    let content: String
    let category: NewsCategory?
    let relatedArticles: [FeedSourceArticle]
    let isHighlight: Bool

    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        category: NewsCategory? = nil,
        relatedArticles: [FeedSourceArticle] = [],
        isHighlight: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.relatedArticles = relatedArticles
        self.isHighlight = isHighlight
    }
}

// MARK: - DigestViewItem Extensions

extension DigestViewItem {
    /// Section markers used in the LLM output format
    private static let sectionMarkers: [NewsCategory: String] = [
        .technology: "[TECHNOLOGY]",
        .business: "[BUSINESS]",
        .world: "[WORLD]",
        .science: "[SCIENCE]",
        .health: "[HEALTH]",
        .sports: "[SPORTS]",
        .entertainment: "[ENTERTAINMENT]",
    ]

    /// Extracts the key insight from the structured summary
    var keyInsight: String {
        // Try to extract content after [KEY INSIGHT] marker
        if let range = summary.range(of: "[KEY INSIGHT]") {
            let afterMarker = summary[range.upperBound...]
            // Find the next section marker or end of string
            let content = extractContentUntilNextMarker(String(afterMarker))
            if !content.isEmpty {
                return content
            }
        }

        // Fallback: use first paragraph
        let paragraphs = summary.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return paragraphs.first ?? summary
    }

    /// Creates one section per category based on source articles and LLM-generated content
    func parseSections(with sourceArticles: [FeedSourceArticle]) -> [DigestSection] {
        // Group articles by category
        var articlesByCategory: [NewsCategory: [FeedSourceArticle]] = [:]

        for article in sourceArticles {
            if let category = article.categoryType {
                articlesByCategory[category, default: []].append(article)
            }
        }

        // No categories with articles - return empty
        guard !articlesByCategory.isEmpty else {
            return []
        }

        // Define category order for consistent display
        let categoryOrder: [NewsCategory] = [
            .technology, .business, .world, .science, .health, .sports, .entertainment,
        ]

        // Create one section per category that has articles
        var sections: [DigestSection] = []

        for category in categoryOrder {
            guard let articles = articlesByCategory[category], !articles.isEmpty else {
                continue
            }

            // Extract content for this category from the structured summary
            let content = extractCategoryContent(for: category, articles: articles)

            sections.append(DigestSection(
                id: "\(id)-section-\(category.rawValue)",
                title: category.displayName,
                content: content,
                category: category,
                relatedArticles: Array(articles.prefix(3)),
                isHighlight: false
            ))
        }

        return sections
    }

    /// Extracts content for a specific category from the structured summary
    private func extractCategoryContent(for category: NewsCategory, articles: [FeedSourceArticle]) -> String {
        guard let marker = Self.sectionMarkers[category],
              let range = summary.range(of: marker)
        else {
            // Marker not found, generate from article titles
            return generateContentFromArticles(articles)
        }

        let afterMarker = summary[range.upperBound...]
        let content = extractContentUntilNextMarker(String(afterMarker))

        if content.isEmpty {
            return generateContentFromArticles(articles)
        }

        return content
    }

    /// Extracts text content until the next section marker or end of string
    private func extractContentUntilNextMarker(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Find the next section marker
        let allMarkers = ["[KEY INSIGHT]", "[TECHNOLOGY]", "[BUSINESS]", "[WORLD]",
                          "[SCIENCE]", "[HEALTH]", "[SPORTS]", "[ENTERTAINMENT]"]

        var endIndex = trimmed.endIndex
        for marker in allMarkers {
            if let range = trimmed.range(of: marker) {
                if range.lowerBound < endIndex {
                    endIndex = range.lowerBound
                }
            }
        }

        let content = String(trimmed[..<endIndex])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return content
    }

    /// Generates a brief content description from article titles (fallback)
    private func generateContentFromArticles(_ articles: [FeedSourceArticle]) -> String {
        guard !articles.isEmpty else {
            return "Your reading in this category."
        }

        // Take up to 2 article titles to create a summary
        let titles = articles.prefix(2).map { $0.title }

        if titles.count == 1 {
            return "Featuring: \(titles[0])"
        } else {
            return "Featuring: \(titles[0]) and more."
        }
    }

    /// Computes category breakdown from source articles
    func computeTopicsBreakdown(from sourceArticles: [FeedSourceArticle]) -> [(NewsCategory, Int)] {
        var categoryCount: [NewsCategory: Int] = [:]

        for article in sourceArticles {
            if let category = article.categoryType {
                categoryCount[category, default: 0] += 1
            }
        }

        return categoryCount
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }
}
