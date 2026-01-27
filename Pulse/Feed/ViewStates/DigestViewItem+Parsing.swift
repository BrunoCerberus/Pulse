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

        // Track parsed content to detect when same LLM-generated content appears for multiple categories
        // This helps prevent the bug where all categories show the same content
        var seenParsedContent = Set<String>()

        for category in categoryOrder {
            guard let articles = articlesByCategory[category], !articles.isEmpty else {
                continue
            }

            // Use pre-parsed content if available, otherwise fallback to extraction
            var content: String
            if let categoryName = Self.categoryNames[category],
               let parsed = parsedContent[categoryName], !parsed.isEmpty
            {
                // Check if this exact parsed content was already used by another category
                // This indicates a parsing failure where all content ended up in one category
                let normalizedParsed = parsed.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if seenParsedContent.contains(normalizedParsed) {
                    // Same content already used - generate fallback instead
                    content = generateContentFromArticles(articles, category: category)
                } else {
                    seenParsedContent.insert(normalizedParsed)
                    content = parsed
                }
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
    /// IMPORTANT: Order matters - most specific patterns first to avoid false positives
    private static func categoryPatterns(for category: String) -> [(pattern: String, markerLength: Int)] {
        [
            // Most reliable: Markdown bold headers (prioritize these)
            ("**\(category)**", 4 + category.count),
            ("**\(category):**", 5 + category.count),
            ("**\(category)** ", 5 + category.count),
            ("**\(category)**\n", 5 + category.count),
            // Markdown heading format
            ("## \(category)\n", 4 + category.count),
            ("## \(category) ", 4 + category.count),
            // List formats with markers (less reliable, require bullet prefix)
            ("\n• \(category):", 3 + category.count),
            ("\n- \(category):", 3 + category.count),
            ("\n• \(category) ", 3 + category.count),
            ("\n- \(category) ", 3 + category.count),
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

    /// Removes duplicate paragraphs/sentences from content (common LLM repetition issue)
    private static func deduplicateContent(_ content: String) -> String {
        // Split into paragraphs (double newline) or sentences
        let paragraphs = content.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // If we have multiple paragraphs, deduplicate them
        if paragraphs.count > 1 {
            var seen = Set<String>()
            var uniqueParagraphs: [String] = []

            for paragraph in paragraphs {
                // Normalize for comparison (lowercase, trimmed)
                let normalized = paragraph.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if !seen.contains(normalized) {
                    seen.insert(normalized)
                    uniqueParagraphs.append(paragraph)
                }
            }

            if uniqueParagraphs.count < paragraphs.count {
                return uniqueParagraphs.joined(separator: "\n\n")
            }
        }

        // Also check for repeated sentences within a single paragraph
        let sentences = content.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if sentences.count > 2 {
            var seen = Set<String>()
            var uniqueSentences: [String] = []

            for sentence in sentences {
                let normalized = sentence.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                // Skip very short fragments and duplicates
                if normalized.count > 10, !seen.contains(normalized) {
                    seen.insert(normalized)
                    uniqueSentences.append(sentence)
                } else if normalized.count <= 10, !sentence.isEmpty {
                    // Keep short fragments (might be important)
                    uniqueSentences.append(sentence)
                }
            }

            if uniqueSentences.count < sentences.count {
                var result = uniqueSentences.joined(separator: ". ")
                // Ensure proper ending
                if !result.hasSuffix(".") && !result.hasSuffix("?") && !result.hasSuffix("!") {
                    result += "."
                }
                return result
            }
        }

        return content
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
                    // Deduplicate to handle LLM repetition issues
                    let deduplicatedContent = Self.deduplicateContent(cleanedContent)
                    result[current.category] = deduplicatedContent
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
            // Only match structured category headers, not category names in prose
            let patterns = [
                "**\(cat)**",
                "\n**\(cat)**",
                "* **\(cat)**",
                "- **\(cat)**",
                "## \(cat)",
                "\n## \(cat)",
            ]
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
        let cleaned = Self.stripCategoryMarkers(from: rawContent)
        return Self.deduplicateContent(cleaned)
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
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        // Apply deduplication to handle LLM repetition
        return Self.deduplicateContent(result)
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
}
