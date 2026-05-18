import Foundation

/// Builds prompts and parses output for on-device topic extraction.
///
/// The model (Gemma 3 1B) is asked for a strict comma-separated list of
/// lowercase kebab-case tags. The parser is **defensive**: small models
/// occasionally return code-fenced output, trailing commentary, or mixed
/// formatting. We tolerate all of that and never trust the model's
/// formatting blindly.
enum TopicExtractionPromptBuilder {
    static let systemPrompt = """
    You are a topic-tagging assistant. Extract 3 to 5 short topic tags from the article below.
    Strict output rules:
    - Output ONLY a comma-separated list of tags, nothing else
    - Each tag is lowercase kebab-case, e.g. artificial-intelligence, climate-change
    - Each tag is 2 to 50 characters
    - Tags describe what the article is ABOUT, not specific named entities
    - No preamble, no explanation, no quotes, no code fences
    """

    static func buildPrompt(title: String, summary: String?) -> String {
        // Sanitize untrusted RSS-sourced text before interpolating into the
        // prompt. The output side is already constrained by `parseTags`.
        let safeTitle = PromptSanitizer.sanitize(title, maxLength: 200)
        var content = "Title: \(safeTitle)"
        if let summary, !summary.isEmpty {
            let safeSummary = PromptSanitizer.sanitize(summary, maxLength: 500)
            if !safeSummary.isEmpty {
                content += "\n\nSummary: \(safeSummary)"
            }
        }
        return "Extract topic tags for this article:\n\n\(content)"
    }

    /// Normalises raw LLM output into a 0–5 element tag array.
    ///
    /// Handles: code-fence wrappers, surrounding quotes/punctuation,
    /// embedded commentary on later lines, mixed-case input, spaces or
    /// underscores in tags, and tags too short / too long.
    static func parseTags(from raw: String) -> [String] {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip surrounding code fences if the model decided to be helpful.
        trimmed = trimmed.replacingOccurrences(
            of: "^```[a-zA-Z]*\\s*",
            with: "",
            options: .regularExpression
        )
        trimmed = trimmed.replacingOccurrences(of: "```", with: "")

        // Take only the first non-empty line — anything after is most likely
        // unsolicited commentary.
        let firstLine = trimmed
            .split(whereSeparator: \.isNewline)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map(String.init) ?? ""

        let parts = firstLine.split(separator: ",", omittingEmptySubsequences: true)

        let tags = parts.compactMap(sanitizeTag)
        var seen = Set<String>()
        var unique: [String] = []
        for tag in tags where !seen.contains(tag) {
            seen.insert(tag)
            unique.append(tag)
        }
        return Array(unique.prefix(5))
    }

    /// Converts a kebab-case tag back to a Title Case display name.
    /// `"artificial-intelligence"` → `"Artificial Intelligence"`.
    static func displayName(for tagID: String) -> String {
        tagID
            .split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }

    private static func sanitizeTag(_ raw: Substring) -> String? {
        var trimmed = String(raw).trimmingCharacters(in: .whitespacesAndNewlines)
        trimmed = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: ".\"'`*[]()<>"))
        trimmed = trimmed
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()

        let allowed = CharacterSet.lowercaseLetters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: "-"))
        let scalars = trimmed.unicodeScalars.filter { allowed.contains($0) }
        var result = String(String.UnicodeScalarView(scalars))
        while result.contains("--") {
            result = result.replacingOccurrences(of: "--", with: "-")
        }
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        guard result.count >= 2, result.count <= 50 else { return nil }
        return result
    }
}
