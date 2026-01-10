import Foundation

// MARK: - Formatted Paragraph

/// Represents a parsed paragraph from AI-generated summary text.
struct FormattedParagraph: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isHeading: Bool
    let isBullet: Bool

    static func == (lhs: FormattedParagraph, rhs: FormattedParagraph) -> Bool {
        lhs.text == rhs.text && lhs.isHeading == rhs.isHeading && lhs.isBullet == rhs.isBullet
    }
}

// MARK: - Summarization Text Formatter

/// Formats raw AI-generated summary text into structured paragraphs.
///
/// Handles:
/// - Bullet points (- or •)
/// - Markdown bold headings (**text**)
/// - Short headings ending with colon
/// - Regular paragraphs
enum SummarizationTextFormatter {
    /// Configuration for text formatting rules.
    enum Config {
        static let maxHeadingLength = 50
        static let maxHeadingWordCount = 5
    }

    /// Parses raw summary text into formatted paragraphs.
    /// - Parameter text: The raw AI-generated summary text.
    /// - Returns: An array of formatted paragraphs.
    static func format(_ text: String) -> [FormattedParagraph] {
        let components = text
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\n- ", with: "\n• ")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return components.map { component in
            if component.hasPrefix("•") {
                return FormattedParagraph(
                    text: String(component.dropFirst()).trimmingCharacters(in: .whitespaces),
                    isHeading: false,
                    isBullet: true
                )
            } else if component.hasPrefix("**"), component.hasSuffix("**") {
                return FormattedParagraph(
                    text: String(component.dropFirst(2).dropLast(2)),
                    isHeading: true,
                    isBullet: false
                )
            } else if isHeading(component) {
                return FormattedParagraph(
                    text: component,
                    isHeading: true,
                    isBullet: false
                )
            } else {
                return FormattedParagraph(
                    text: component,
                    isHeading: false,
                    isBullet: false
                )
            }
        }
    }

    /// Determines if a component should be treated as a heading.
    private static func isHeading(_ component: String) -> Bool {
        component.count < Config.maxHeadingLength &&
            component.hasSuffix(":") &&
            !component.contains(".") &&
            component.split(separator: " ").count <= Config.maxHeadingWordCount
    }
}
