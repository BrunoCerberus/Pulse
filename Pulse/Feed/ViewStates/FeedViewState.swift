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
    /// Category markers in various formats the LLM might use
    private static let categoryPatterns: [NewsCategory: [String]] = [
        .technology: ["**Technology**", "**technology**", "[TECHNOLOGY]", "## Technology"],
        .business: ["**Business**", "**business**", "[BUSINESS]", "## Business"],
        .world: ["**World**", "**world**", "[WORLD]", "## World"],
        .science: ["**Science**", "**science**", "[SCIENCE]", "## Science"],
        .health: ["**Health**", "**health**", "[HEALTH]", "## Health"],
        .sports: ["**Sports**", "**sports**", "[SPORTS]", "## Sports"],
        .entertainment: ["**Entertainment**", "**entertainment**", "[ENTERTAINMENT]", "## Entertainment"],
    ]

    /// Extracts the key insight (overall summary before any category sections)
    var keyInsight: String {
        // Find the first category marker position
        var firstCategoryPosition = summary.endIndex

        for patterns in Self.categoryPatterns.values {
            for pattern in patterns {
                if let range = summary.range(of: pattern) {
                    if range.lowerBound < firstCategoryPosition {
                        firstCategoryPosition = range.lowerBound
                    }
                }
            }
        }

        // Extract text before the first category
        let overallSummary = String(summary[..<firstCategoryPosition])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Clean up any markers that might be at the start
        let cleaned = cleanText(overallSummary)

        if !cleaned.isEmpty {
            return cleaned
        }

        // Fallback: first paragraph
        let paragraphs = summary.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !isCategoryHeader($0) }

        return paragraphs.first ?? "A summary of your recent reading."
    }

    /// Checks if text starts with a category header
    private func isCategoryHeader(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let categories = ["technology", "business", "world", "science", "health", "sports", "entertainment"]
        for category in categories {
            if lowercased.hasPrefix("**\(category)") || lowercased.hasPrefix("[\(category.uppercased())]") {
                return true
            }
        }
        return false
    }

    /// Cleans text by removing markers and placeholder content
    private func cleanText(_ text: String) -> String {
        var result = text

        // Remove bracket markers
        let bracketMarkers = ["[KEY INSIGHT]", "[TECHNOLOGY]", "[BUSINESS]", "[WORLD]",
                              "[SCIENCE]", "[HEALTH]", "[SPORTS]", "[ENTERTAINMENT]"]
        for marker in bracketMarkers {
            result = result.replacingOccurrences(of: marker, with: "")
        }

        // Check for placeholder text
        let lowercased = result.lowercased()
        if lowercased.contains("2-3 sentence") || lowercased.contains("overview of the main themes") {
            return ""
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
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
        guard let patterns = Self.categoryPatterns[category] else {
            return generateContentFromArticles(articles)
        }

        // Try each pattern to find the category section
        for pattern in patterns {
            if let range = summary.range(of: pattern) {
                let afterMarker = summary[range.upperBound...]
                let content = extractContentUntilNextCategory(String(afterMarker))

                if !content.isEmpty {
                    return content
                }
            }
        }

        // No marker found, use fallback
        return generateContentFromArticles(articles)
    }

    /// Extracts text content until the next category marker or end of string
    private func extractContentUntilNextCategory(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Find the next category marker position
        var endIndex = trimmed.endIndex

        for patterns in Self.categoryPatterns.values {
            for pattern in patterns {
                if let range = trimmed.range(of: pattern) {
                    if range.lowerBound < endIndex {
                        endIndex = range.lowerBound
                    }
                }
            }
        }

        let content = String(trimmed[..<endIndex])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return content
    }

    /// Generates a brief content description from article count (fallback)
    private func generateContentFromArticles(_ articles: [FeedSourceArticle]) -> String {
        let count = articles.count
        if count == 1 {
            return "You read 1 article in this category."
        } else {
            return "You read \(count) articles in this category."
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
