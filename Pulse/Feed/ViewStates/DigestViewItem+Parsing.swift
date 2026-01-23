import Foundation

// MARK: - DigestViewItem Parsing Extensions

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

    /// Category-specific intro phrases for natural language generation
    private static let categoryIntros: [NewsCategory: [String]] = [
        .technology: ["Your tech reading covered", "In the tech world, you explored", "On the technology front,"],
        .business: ["From the business sector,", "Your business reading included", "In markets and business,"],
        .world: ["Around the globe,", "In international news,", "From world affairs,"],
        .science: ["In scientific developments,", "Your science reading featured", "From the world of science,"],
        .health: ["In health and wellness,", "Your health reading covered", "On the health front,"],
        .sports: ["In sports coverage,", "From the sports world,", "Your sports reading included"],
        .entertainment: [
            "In entertainment news,", "From the entertainment world,", "Your entertainment reading featured",
        ],
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
    private static func categoryPatterns(for category: String) -> [(pattern: String, markerLength: Int)] {
        [
            ("**\(category)**", 4 + category.count),
            ("**\(category):**", 5 + category.count),
            ("**\(category)** ", 5 + category.count),
            ("**\(category)**\n", 5 + category.count),
            ("## \(category)\n", 4 + category.count),
            ("## \(category) ", 4 + category.count),
            ("\n\(category):", 2 + category.count),
            ("\n\(category) ", 2 + category.count),
            ("• \(category)", 2 + category.count),
            ("- \(category)", 2 + category.count),
        ]
    }

    /// All category names for stripping from content
    private static let allCategoryNames = [
        "technology", "business", "world", "science", "health", "sports", "entertainment",
    ]

    /// Strips any remaining category markers from extracted content
    private static func stripCategoryMarkers(from content: String) -> String {
        var result = content

        for category in allCategoryNames {
            result = result.replacingOccurrences(
                of: "\\*\\*\(category)\\*\\*:?",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            result = result.replacingOccurrences(
                of: "## \(category)",
                with: "",
                options: .caseInsensitive
            )
        }

        result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Parses all category content from the summary in a single pass
    private func parseAllCategoryContent(from text: String) -> [String: String] {
        var result: [String: String] = [:]
        let normalizedText = text.lowercased()
        let originalText = text

        let allCategories = Array(Self.categoryNames.values)
        var categoryPositions: [(category: String, range: Range<String.Index>)] = []

        for category in allCategories {
            let patterns = Self.categoryPatterns(for: category)

            for (pattern, _) in patterns {
                if let range = normalizedText.range(of: pattern) {
                    categoryPositions.append((category: category, range: range))
                    break
                }
            }
        }

        categoryPositions.sort { $0.range.lowerBound < $1.range.lowerBound }

        for (index, current) in categoryPositions.enumerated() {
            let startIndex = current.range.upperBound
            let endIndex: String.Index

            if index + 1 < categoryPositions.count {
                endIndex = categoryPositions[index + 1].range.lowerBound
            } else {
                endIndex = normalizedText.endIndex
            }

            if startIndex < endIndex {
                let rawContent = String(originalText[startIndex ..< endIndex])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanedContent = Self.stripCategoryMarkers(from: rawContent)

                if !cleanedContent.isEmpty {
                    result[current.category] = cleanedContent
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

        let normalizedText = summary.lowercased()
        let originalText = summary
        let categoryLower = categoryName.lowercased()

        let patterns = Self.categoryPatterns(for: categoryLower)

        for (pattern, _) in patterns {
            if let markerRange = normalizedText.range(of: pattern) {
                let afterMarkerOriginal = String(originalText[markerRange.upperBound...])
                let afterMarkerNormalized = String(normalizedText[markerRange.upperBound...])
                let content = extractContentUntilNextCategory(
                    afterMarkerOriginal,
                    normalizedText: afterMarkerNormalized
                )
                if !content.isEmpty {
                    return cleanCategoryContent(content)
                }
            }
        }

        if let content = extractWithRegex(category: categoryLower, from: originalText) {
            return content
        }

        return generateContentFromArticles(articles, category: category)
    }

    /// Uses regex to find category content more flexibly
    private func extractWithRegex(category: String, from text: String) -> String? {
        let allCategories = "technology|business|world|science|health|sports|entertainment"
        // swiftlint:disable:next line_length
        let pattern = "(?:\\*\\*\(category)\\*\\*|\\b\(category)\\b[:\\-]?)\\s*(.+?)(?=\\*\\*(?:\(allCategories))\\*\\*|\\b(?:\(allCategories))\\b[:\\-]|$)"

        let regexOptions: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        guard let regex = try? NSRegularExpression(pattern: pattern, options: regexOptions) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           let contentRange = Range(match.range(at: 1), in: text)
        {
            let rawContent = String(text[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !rawContent.isEmpty {
                let cleaned = Self.stripCategoryMarkers(from: rawContent)
                return cleanCategoryContent(cleaned)
            }
        }

        return nil
    }

    /// Extracts text content until the next category marker or end of string
    private func extractContentUntilNextCategory(_ originalText: String, normalizedText: String? = nil) -> String {
        let trimmedOriginal = originalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchText = (normalizedText ?? originalText.lowercased())
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let categories = ["technology", "business", "world", "science", "health", "sports", "entertainment"]
        var earliestEnd = trimmedOriginal.endIndex

        for cat in categories {
            let patterns = ["**\(cat)**", "* **\(cat)**", "- **\(cat)**", "## \(cat)"]
            for pattern in patterns {
                if let range = searchText.range(of: pattern) {
                    let offset = searchText.distance(from: searchText.startIndex, to: range.lowerBound)
                    if offset < trimmedOriginal.count {
                        let originalIndex = trimmedOriginal.index(trimmedOriginal.startIndex, offsetBy: offset)
                        if originalIndex < earliestEnd {
                            earliestEnd = originalIndex
                        }
                    }
                }
            }
        }

        let rawContent = String(trimmedOriginal[..<earliestEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
        return Self.stripCategoryMarkers(from: rawContent)
    }

    /// Cleans category content by removing bullet points and markdown
    private func cleanCategoryContent(_ content: String) -> String {
        var result = content
        result = Self.stripCategoryMarkers(from: result)

        let lines = result.components(separatedBy: "\n")
            .map { line -> String in
                var cleaned = line.trimmingCharacters(in: .whitespaces)
                let prefixes = ["+ ", "- ", "* ", "• "]
                for prefix in prefixes where cleaned.hasPrefix(prefix) {
                    cleaned = String(cleaned.dropFirst(prefix.count))
                    break
                }
                return cleaned
            }
            .filter { !$0.isEmpty }

        result = lines.joined(separator: " ")
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

        let defaultIntros = ["You read about", "Your reading covered", "Notable stories included"]
        let intros = category.flatMap { Self.categoryIntros[$0] } ?? defaultIntros
        let intro = intros[articleCount % intros.count]

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
