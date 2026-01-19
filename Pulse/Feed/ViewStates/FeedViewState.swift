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
    /// Category names for pattern matching (case-insensitive)
    private static let categoryNames: [NewsCategory: String] = [
        .technology: "technology",
        .business: "business",
        .world: "world",
        .science: "science",
        .health: "health",
        .sports: "sports",
        .entertainment: "entertainment",
    ]

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

        // Pre-parse all category content from the summary once
        let parsedContent = parseAllCategoryContent(from: summary)

        // Create one section per category that has articles
        var sections: [DigestSection] = []

        for category in categoryOrder {
            guard let articles = articlesByCategory[category], !articles.isEmpty else {
                continue
            }

            // Use pre-parsed content if available, otherwise fallback to extraction
            let content: String
            if let categoryName = Self.categoryNames[category],
               let parsed = parsedContent[categoryName], !parsed.isEmpty
            {
                content = parsed
            } else {
                content = extractCategoryContent(for: category, articles: articles)
            }

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

    /// Shared patterns for category marker matching
    /// Returns array of (pattern, markerLength) tuples for the given category name
    private static func categoryPatterns(for category: String) -> [(pattern: String, markerLength: Int)] {
        [
            ("**\(category)**", 4 + category.count), // **technology**
            ("**\(category):**", 5 + category.count), // **technology:**
            ("**\(category)** ", 5 + category.count), // **technology** (with space)
            ("**\(category)**\n", 5 + category.count), // **technology**(newline)
            ("## \(category)\n", 4 + category.count), // ## technology(newline)
            ("## \(category) ", 4 + category.count), // ## technology (space)
            ("\n\(category):", 2 + category.count), // newline + technology:
            ("\n\(category) ", 2 + category.count), // newline + technology (space)
            ("• \(category)", 2 + category.count), // bullet point
            ("- \(category)", 2 + category.count), // dash bullet
            ("\(category):", 1 + category.count), // technology: (at any position)
        ]
    }

    /// Parses all category content from the summary in a single pass
    /// Returns a dictionary mapping lowercase category names to their content
    private func parseAllCategoryContent(from text: String) -> [String: String] {
        var result: [String: String] = [:]

        // Work entirely with lowercased text to avoid Unicode index misalignment
        // (lowercasing can change character counts in some locales)
        let normalizedText = text.lowercased()

        // Find all category markers and their positions
        let allCategories = Array(Self.categoryNames.values)
        var categoryPositions: [(category: String, range: Range<String.Index>)] = []

        for category in allCategories {
            let patterns = Self.categoryPatterns(for: category)

            for (pattern, _) in patterns {
                if let range = normalizedText.range(of: pattern) {
                    categoryPositions.append((category: category, range: range))
                    break // Found this category, move to next
                }
            }
        }

        // Sort by position to get categories in order they appear
        categoryPositions.sort { $0.range.lowerBound < $1.range.lowerBound }

        // Extract content between each category marker and the next
        for (index, current) in categoryPositions.enumerated() {
            let startIndex = current.range.upperBound
            let endIndex: String.Index

            if index + 1 < categoryPositions.count {
                // Content ends where the next category starts
                endIndex = categoryPositions[index + 1].range.lowerBound
            } else {
                // Last category - content goes to end
                endIndex = normalizedText.endIndex
            }

            if startIndex < endIndex {
                let content = String(normalizedText[startIndex ..< endIndex])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "**", with: "")

                if !content.isEmpty {
                    result[current.category] = content
                }
            }
        }

        return result
    }

    /// Extracts content for a specific category from the structured summary
    private func extractCategoryContent(for category: NewsCategory, articles: [FeedSourceArticle]) -> String {
        guard let categoryName = Self.categoryNames[category] else {
            return generateContentFromArticles(articles, category: category)
        }

        // Work entirely with lowercased text to avoid Unicode index misalignment
        let normalizedText = summary.lowercased()
        let categoryLower = categoryName.lowercased()

        // Use shared patterns for consistency
        let patterns = Self.categoryPatterns(for: categoryLower)

        for (pattern, _) in patterns {
            if let markerRange = normalizedText.range(of: pattern) {
                // Extract content after the marker from the same normalized text
                let afterMarker = String(normalizedText[markerRange.upperBound...])
                let content = extractContentUntilNextCategory(afterMarker)
                if !content.isEmpty {
                    return cleanCategoryContent(content)
                }
            }
        }

        // Try a more flexible regex-based approach as last resort
        if let content = extractWithRegex(category: categoryLower, from: normalizedText) {
            return content
        }

        // Fallback: no content found for this category
        return generateContentFromArticles(articles, category: category)
    }

    /// Uses regex to find category content more flexibly
    private func extractWithRegex(category: String, from text: String) -> String? {
        // Match: **Category** or Category: followed by content until next category or end
        let allCategories = "technology|business|world|science|health|sports|entertainment"
        let pattern = "(?:\\*\\*\(category)\\*\\*|\\b\(category)\\b[:\\-]?)\\s*(.+?)(?=\\*\\*(?:\(allCategories))\\*\\*|\\b(?:\(allCategories))\\b[:\\-]|$)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           let contentRange = Range(match.range(at: 1), in: text)
        {
            let content = String(text[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                return cleanCategoryContent(content)
            }
        }

        return nil
    }

    /// Extracts text content until the next category marker or end of string
    private func extractContentUntilNextCategory(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchText = trimmed.lowercased()

        // Find the earliest next category marker
        let categories = ["technology", "business", "world", "science", "health", "sports", "entertainment"]
        var earliestEnd = trimmed.endIndex

        for cat in categories {
            // Check multiple patterns
            let patterns = ["**\(cat)**", "* **\(cat)**", "- **\(cat)**", "## \(cat)", "\(cat):"]
            for pattern in patterns {
                if let range = searchText.range(of: pattern) {
                    let offset = searchText.distance(from: searchText.startIndex, to: range.lowerBound)
                    let originalIndex = trimmed.index(trimmed.startIndex, offsetBy: offset)
                    if originalIndex < earliestEnd {
                        earliestEnd = originalIndex
                    }
                }
            }
        }

        return String(trimmed[..<earliestEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Cleans category content by removing bullet points and markdown
    private func cleanCategoryContent(_ content: String) -> String {
        var result = content

        // Remove leading bullet points, plus signs, dashes
        let lines = result.components(separatedBy: "\n")
            .map { line -> String in
                var cleaned = line.trimmingCharacters(in: .whitespaces)
                // Remove common bullet prefixes
                let prefixes = ["+ ", "- ", "* ", "• "]
                for prefix in prefixes {
                    if cleaned.hasPrefix(prefix) {
                        cleaned = String(cleaned.dropFirst(prefix.count))
                    }
                }
                return cleaned
            }
            .filter { !$0.isEmpty }

        result = lines.joined(separator: " ")

        // Remove any remaining markdown bold markers
        result = result.replacingOccurrences(of: "**", with: "")

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Generates a humanized summary from article titles when LLM parsing fails
    private func generateContentFromArticles(_ articles: [FeedSourceArticle], category: NewsCategory? = nil) -> String {
        guard !articles.isEmpty else {
            return "No articles in this category."
        }

        let topArticles = Array(articles.prefix(3))
        let sources = Set(topArticles.map { $0.source }).joined(separator: ", ")
        let articleCount = articles.count

        // Category-specific intros for more natural language
        let categoryIntros: [NewsCategory: [String]] = [
            .technology: [
                "Your tech reading covered",
                "In the tech world, you explored",
                "On the technology front,",
            ],
            .business: [
                "From the business sector,",
                "Your business reading included",
                "In markets and business,",
            ],
            .world: [
                "Around the globe,",
                "In international news,",
                "From world affairs,",
            ],
            .science: [
                "In scientific developments,",
                "Your science reading featured",
                "From the world of science,",
            ],
            .health: [
                "In health and wellness,",
                "Your health reading covered",
                "On the health front,",
            ],
            .sports: [
                "In sports coverage,",
                "From the sports world,",
                "Your sports reading included",
            ],
            .entertainment: [
                "In entertainment news,",
                "From the entertainment world,",
                "Your entertainment reading featured",
            ],
        ]

        // Pick a semi-random intro based on article count (for variety)
        let intros = category.flatMap { categoryIntros[$0] } ?? ["You read about", "Your reading covered", "Notable stories included"]
        let intro = intros[articleCount % intros.count]

        // Build the summary based on article count
        if topArticles.count == 1 {
            let article = topArticles[0]
            return "\(intro) \"\(article.title)\" from \(article.source)."
        } else if topArticles.count == 2 {
            return "\(intro) stories like \"\(topArticles[0].title)\" and coverage from \(sources)."
        } else {
            let moreCount = articleCount > 3 ? " and \(articleCount - 2) more" : ""
            return "\(intro) \"\(topArticles[0].title),\" plus stories from \(sources)\(moreCount)."
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
