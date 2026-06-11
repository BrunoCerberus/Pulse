import Foundation

/// Builds clean, narratable text for the playback queue.
///
/// Single source of truth for speech-text composition: the article path is the
/// logic previously embedded in `ArticleDetailDomainInteractor`, extracted so
/// the briefing queue and the single-article "Listen" can never drift apart.
/// All members are `nonisolated` so callers can compose text off the main actor.
enum SpeechTextBuilder {
    /// Narration text for one article: title, author, description, and full
    /// content — HTML-stripped, truncation markers removed, and known
    /// scraper-injected error phrases filtered out.
    nonisolated static func speechText(for article: Article) -> String {
        var parts: [String] = [article.title]

        if let author = article.author, !author.isEmpty {
            parts.append("By \(author)")
        }

        if let description = article.description {
            let clean = stripHTML(from: description).trimmingCharacters(in: .whitespacesAndNewlines)
            if !clean.isEmpty {
                parts.append(clean)
            }
        }

        if let content = article.content {
            let clean = stripHTML(from: stripTruncationMarker(from: content))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let filtered = filterKnownErrorContent(from: clean), !filtered.isEmpty {
                parts.append(filtered)
            }
        }

        return parts.joined(separator: ". ")
    }

    /// Narration text for the AI daily digest: a localized spoken intro
    /// followed by the digest summary with all markdown formatting removed
    /// (the LLM emits `**Category**` headers, which would otherwise be read
    /// as "asterisk asterisk").
    nonisolated static func speechText(forDigestSummary summary: String) -> String {
        let intro = AppLocalization.localized("briefing.intro")
        let cleanSummary = stripMarkdown(from: summary)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanSummary.isEmpty else { return intro }
        return "\(intro)\n\n\(cleanSummary)"
    }

    // MARK: - Cleaning Helpers

    nonisolated static func stripHTML(from html: String) -> String {
        html.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    nonisolated static func stripTruncationMarker(from content: String) -> String {
        let pattern = #"\s*\[\+\d+ chars\]"#
        return content.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }

    /// Removes markdown structure the TTS engine would read literally:
    /// bold/italic markers, heading hashes, and list bullets.
    nonisolated static func stripMarkdown(from text: String) -> String {
        text
            .replacingOccurrences(of: #"\*{1,2}([^*]+)\*{1,2}"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"(?m)^#{1,6}\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?m)^\s*[-*•]\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[ \t]+"#, with: " ", options: .regularExpression)
    }

    /// Known scraper-injected error phrases from The Guardian and similar sites.
    nonisolated static let knownErrorPhrases: [String] = [
        "A required part of this site couldn't load.",
        "This may be due to a browser extension, network issues, or browser settings.",
        "Please check your connection, disable any ad blockers, or try a different browser.",
        "Please check your connection, disable any ad blockers",
        "We noticed you're using an ad blocker",
        "Please disable your ad blocker",
        "JavaScript must be enabled",
        "You need to enable JavaScript to run this app",
        "This content is only available with JavaScript",
        "Please enable JavaScript",
        "Your browser does not support JavaScript",
    ]

    /// Filters out known error/noise patterns injected by content scrapers
    /// (e.g. go-readability picking up Guardian anti-adblock banners). Returns
    /// the cleaned content, or `nil` if nothing useful remains.
    nonisolated static func filterKnownErrorContent(from content: String) -> String? {
        var cleaned = content

        for phrase in knownErrorPhrases {
            cleaned = cleaned.replacingOccurrences(of: phrase, with: "", options: .caseInsensitive)
        }

        let result = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
}
