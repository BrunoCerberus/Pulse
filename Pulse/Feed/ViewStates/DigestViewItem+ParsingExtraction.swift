import Foundation

extension DigestViewItem {
    /// Extracts content for a specific category from the structured summary
    func extractCategoryContent(for category: NewsCategory, articles: [FeedSourceArticle]) -> String {
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
    func extractWithRegex(category: String, from text: String) -> String? {
        let allCategories = "technology|business|world|science|health|sports|entertainment"
        // swiftlint:disable:next line_length
        let pattern = "(?:\\*\\*\(category)\\*\\*|\\[\(category)\\]|\\b\(category)\\b[:\\-]?)\\s*(.+?)(?=\\*\\*(?:\(allCategories))\\*\\*|\\[(?:\(allCategories))\\]|\\b(?:\(allCategories))\\b[:\\-]|$)"

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
    func extractContentUntilNextCategory(_ originalText: String, normalizedText: String? = nil) -> String {
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
                // Numbered list with bold (LFM 2.5)
                "\n1. **\(cat)**",
                "\n2. **\(cat)**",
                "\n3. **\(cat)**",
                "\n4. **\(cat)**",
                "\n5. **\(cat)**",
                "\n6. **\(cat)**",
                "\n7. **\(cat)**",
                // Heading formats
                "## \(cat)",
                "\n## \(cat)",
                "# \(cat)",
                "\n# \(cat)",
                "### \(cat)",
                "\n### \(cat)",
                // Bracket and bare colon
                "\n[\(cat)]",
                "[\(cat)]",
                "\n\(cat):",
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

    /// Cleans category content by removing bullet points and markdown, preserving paragraph breaks
    func cleanCategoryContent(_ content: String) -> String {
        var result = content
        result = Self.stripCategoryMarkers(from: result)

        // Strip leading colons/dashes left over from category headers
        result = result.replacingOccurrences(of: #"^[:\-–—]\s*"#, with: "", options: .regularExpression)

        // Strip bold markdown
        result = result.replacingOccurrences(of: "**", with: "")

        // Strip inline source references like "(BBC News - Health, Health)"
        result = result.replacingOccurrences(
            of: #"\([^)]*(?:News|Guardian|BBC|Reuters|CNN|Times)[^)]*\)"#,
            with: "",
            options: .regularExpression
        )

        // Process line by line: strip bullets but preserve paragraph structure
        let paragraphs = result.components(separatedBy: "\n\n")
        let cleanedParagraphs = paragraphs.map { paragraph -> String in
            let lines = paragraph.components(separatedBy: "\n")
                .map { line -> String in
                    var cleaned = line.trimmingCharacters(in: .whitespaces)
                    let prefixes = ["+ ", "- ", "* ", "• ", "· "]
                    for prefix in prefixes where cleaned.hasPrefix(prefix) {
                        cleaned = String(cleaned.dropFirst(prefix.count))
                        break
                    }
                    // Strip numbered list prefixes (e.g. "1. ", "2. ")
                    if let range = cleaned.range(
                        of: #"^\d+\.\s+"#,
                        options: .regularExpression
                    ) {
                        cleaned = String(cleaned[range.upperBound...])
                    }
                    return cleaned
                }
                .filter { !$0.isEmpty }
            return lines.joined(separator: " ")
        }
        .filter { !$0.isEmpty }

        // Cap paragraphs per section to prevent repetition-bloated output
        let cappedParagraphs = Array(cleanedParagraphs.prefix(LLMConfiguration.maxParagraphsPerSection))

        // Collapse excessive dashes/em-dashes from stripped sources
        result = cappedParagraphs.joined(separator: "\n\n")
        result = result.replacingOccurrences(of: " — —", with: " —")
        result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        return Self.deduplicateContent(result)
    }

    /// Generates a humanized summary from article titles when LLM parsing fails
    func generateContentFromArticles(_ articles: [FeedSourceArticle], category: NewsCategory? = nil) -> String {
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
