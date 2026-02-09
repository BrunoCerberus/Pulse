import Foundation

// MARK: - DigestViewItem Parsing Extensions

extension DigestViewItem {
    /// Category names for pattern matching (case-insensitive)
    static let categoryNames: [NewsCategory: String] = [
        .technology: "technology",
        .business: "business",
        .world: "world",
        .science: "science",
        .health: "health",
        .sports: "sports",
        .entertainment: "entertainment",
    ]

    /// Category-specific intro phrases for natural language generation
    static let categoryIntros: [NewsCategory: [String]] = [
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
                let normalizedParsed = parsed.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if seenParsedContent.contains(normalizedParsed) {
                    content = generateContentFromArticles(articles, category: category)
                } else if Self.containsOtherCategorySubjects(normalizedParsed, excluding: categoryName) {
                    // Content mentions other categories as subjects — LLM mixed categories
                    content = generateContentFromArticles(articles, category: category)
                } else {
                    seenParsedContent.insert(normalizedParsed)
                    content = parsed
                }
            } else {
                content = extractCategoryContent(for: category, articles: articles)
            }

            // Apply paragraph cap and deduplication to all content sources
            let finalContent = Self.capAndDeduplicateContent(content)

            sections.append(DigestSection(
                id: "\(id)-section-\(category.rawValue)",
                title: category.displayName,
                content: finalContent,
                category: category,
                relatedArticles: Array(articles.prefix(3)),
                isHighlight: false
            ))
        }

        return sections
    }

    /// Shared patterns for category marker matching
    /// IMPORTANT: Order matters - most specific patterns first to avoid content leakage
    static func categoryPatterns(for category: String) -> [(pattern: String, markerLength: Int)] {
        [
            // 1. Numbered list with bold (LFM 2.5) - MUST be before plain bold
            //    Captures the \n so previous category content ends cleanly
            ("\n1. **\(category)**", 7 + category.count),
            ("\n2. **\(category)**", 7 + category.count),
            ("\n3. **\(category)**", 7 + category.count),
            ("\n4. **\(category)**", 7 + category.count),
            ("\n5. **\(category)**", 7 + category.count),
            ("\n6. **\(category)**", 7 + category.count),
            ("\n7. **\(category)**", 7 + category.count),
            // 2. Heading formats
            ("## \(category)\n", 4 + category.count),
            ("## \(category) ", 4 + category.count),
            ("# \(category)\n", 3 + category.count),
            ("# \(category) ", 3 + category.count),
            ("### \(category)\n", 5 + category.count),
            ("### \(category) ", 5 + category.count),
            // 3. Bold with colon - BEFORE plain bold to avoid colon leaking into content
            ("**\(category):**", 5 + category.count),
            // 4. Bold with space/newline
            ("**\(category)** ", 5 + category.count),
            ("**\(category)**\n", 5 + category.count),
            // 5. Plain bold - most general, LAST among bold patterns
            ("**\(category)**", 4 + category.count),
            // 6. Bracket format (LLM sometimes echoes input formatting)
            ("\n[\(category)]", 3 + category.count),
            ("[\(category)]", 2 + category.count),
            // 7. Bare category with colon
            ("\n\(category):", 2 + category.count),
            // 8. List formats with markers
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

    /// Detects if content mentions other categories as sentence subjects,
    /// indicating the LLM wrote one mixed paragraph instead of separate sections
    private static func containsOtherCategorySubjects(_ content: String, excluding category: String) -> Bool {
        let otherCategories = allCategoryNames.filter { $0 != category }
        var matches = 0
        for other in otherCategories {
            // Match patterns like "Business news reveals", "Health reports", "Science continues"
            // These indicate the LLM is discussing another category's content inline
            let pattern = "\\b\(other)\\s+(?:news|report|update|coverage|sector|analysis|development)"
            if content.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                matches += 1
            }
        }
        // If 2+ other categories are mentioned as subjects, the content is mixed
        return matches >= 2
    }

    /// Strips any remaining category markers from extracted content
    static func stripCategoryMarkers(from content: String) -> String {
        var result = content

        for category in allCategoryNames {
            result = result.replacingOccurrences(
                of: "\\*\\*\(category)\\*\\*:?",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            result = result.replacingOccurrences(
                of: "#{1,3} \(category)",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            result = result.replacingOccurrences(
                of: "\\[\(category)\\]:?",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Computes word overlap ratio between two strings (0.0 to 1.0)
    /// Uses significant words (>3 chars) to avoid matching on common stop words
    private static func wordOverlap(_ lhs: String, _ rhs: String) -> Double {
        let wordsLHS = Set(
            lhs.lowercased()
                .split(whereSeparator: { !$0.isLetter })
                .filter { $0.count > 3 }
        )
        let wordsRHS = Set(
            rhs.lowercased()
                .split(whereSeparator: { !$0.isLetter })
                .filter { $0.count > 3 }
        )
        guard !wordsLHS.isEmpty, !wordsRHS.isEmpty else { return 0 }
        let intersection = wordsLHS.intersection(wordsRHS).count
        let smaller = min(wordsLHS.count, wordsRHS.count)
        return Double(intersection) / Double(smaller)
    }

    /// Removes duplicate and near-duplicate paragraphs/sentences from content
    /// Uses fuzzy word-overlap matching to catch paraphrased repetition from small LLMs
    static func deduplicateContent(_ content: String) -> String {
        let paragraphs = content.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Fuzzy paragraph deduplication
        if paragraphs.count > 1 {
            var uniqueParagraphs: [String] = []

            for paragraph in paragraphs {
                let isSimilar = uniqueParagraphs.contains { existing in
                    wordOverlap(existing, paragraph) > 0.5
                }
                if !isSimilar {
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
            var uniqueSentences: [String] = []

            for sentence in sentences {
                let normalized = sentence.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                guard normalized.count > 10 else {
                    uniqueSentences.append(sentence)
                    continue
                }
                let isSimilar = uniqueSentences.contains { existing in
                    wordOverlap(existing, sentence) > 0.5
                }
                if !isSimilar {
                    uniqueSentences.append(sentence)
                }
            }

            if uniqueSentences.count < sentences.count {
                var result = uniqueSentences.joined(separator: ". ")
                if !result.hasSuffix(".") && !result.hasSuffix("?") && !result.hasSuffix("!") {
                    result += "."
                }
                return result
            }
        }

        return content
    }

    /// Caps paragraphs and deduplicates content for final display
    private static func capAndDeduplicateContent(_ content: String) -> String {
        let deduplicated = deduplicateContent(content)
        let paragraphs = deduplicated.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let capped = Array(paragraphs.prefix(LLMConfiguration.maxParagraphsPerSection))
        return capped.joined(separator: "\n\n")
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
}
