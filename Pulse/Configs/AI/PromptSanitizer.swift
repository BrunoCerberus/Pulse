import Foundation

/// Defensive sanitization for untrusted text (article titles, descriptions,
/// content) before interpolation into LLM prompts.
///
/// **Threat model**: an attacker-controlled RSS source publishes an article
/// whose title or body contains prompt-injection payloads ("Ignore previous
/// instructions...") aimed at hijacking the on-device LLM into producing
/// misleading summaries, polluted topic tags (which sync to CloudKit), or
/// off-topic content.
///
/// **Mitigations applied here**:
/// 1. Map control characters (newlines, tabs, etc.) to spaces — these are the
///    primary vectors used to break out of an in-prompt context.
/// 2. Strip code-fence backticks — small models often treat fenced blocks
///    as instruction boundaries.
/// 3. Collapse whitespace runs and hard-cap the length so a single hostile
///    field can't dominate the prompt window.
///
/// **NOT a complete defense.** LLMs are inherently susceptible to prompt
/// injection, and a small on-device model is more so. This raises the bar
/// substantially without claiming to eliminate the risk. Always treat
/// model output as untrusted before persisting it to a synced store or
/// rendering it in a privileged context. See
/// `TopicExtractionPromptBuilder.parseTags` for an example of output-side
/// validation that complements this input-side sanitization.
enum PromptSanitizer {
    /// Sanitizes a string for safe interpolation into an LLM prompt.
    /// - Parameters:
    ///   - text: Untrusted input (article title, source name, etc).
    ///   - maxLength: Hard length cap; the result is truncated to fit.
    static func sanitize(_ text: String, maxLength: Int) -> String {
        guard maxLength > 0 else { return "" }

        // Map every Unicode control character (newlines, tabs, BEL, DEL, …) to a
        // space. Replacing rather than deleting prevents adjacent words from being
        // glued together when a line break separated them, and neutralizes the
        // control characters most often used to break out of an in-prompt context.
        let space = Unicode.Scalar(0x20)!
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            scalars.append(CharacterSet.controlCharacters.contains(scalar) ? space : scalar)
        }
        var result = String(scalars)

        // Strip backticks so the model can't be tricked into a fenced block.
        result = result.replacing("`", with: "'")

        // Collapse runs of whitespace and trim.
        result = result.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)

        if result.count > maxLength {
            result = String(result.prefix(maxLength))
        }
        return result
    }
}
