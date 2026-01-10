import Foundation
@testable import Pulse
import Testing

// MARK: - Basic Formatting Tests

@Suite("SummarizationTextFormatter Basic Formatting")
struct SummarizationTextFormatterBasicTests {
    @Test("Empty text returns empty array")
    func emptyTextReturnsEmpty() {
        let result = SummarizationTextFormatter.format("")
        #expect(result.isEmpty)
    }

    @Test("Whitespace only text returns empty array")
    func whitespaceOnlyReturnsEmpty() {
        let result = SummarizationTextFormatter.format("   \n\n   ")
        #expect(result.isEmpty)
    }

    @Test("Single paragraph is parsed correctly")
    func singleParagraph() {
        let result = SummarizationTextFormatter.format("This is a simple paragraph.")
        #expect(result.count == 1)
        #expect(result[0].text == "This is a simple paragraph.")
        #expect(!result[0].isHeading)
        #expect(!result[0].isBullet)
    }

    @Test("Multiple paragraphs separated by newlines")
    func multipleParagraphs() {
        let text = "First paragraph.\nSecond paragraph.\nThird paragraph."
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 3)
        #expect(result[0].text == "First paragraph.")
        #expect(result[1].text == "Second paragraph.")
        #expect(result[2].text == "Third paragraph.")
    }

    @Test("Escaped newlines are converted")
    func escapedNewlines() {
        let text = "First line.\\nSecond line."
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 2)
        #expect(result[0].text == "First line.")
        #expect(result[1].text == "Second line.")
    }
}

// MARK: - Bullet Point Tests

@Suite("SummarizationTextFormatter Bullet Points")
struct SummarizationTextFormatterBulletTests {
    @Test("Bullet points with bullet character are parsed")
    func bulletCharacter() {
        let text = "• First item\n• Second item"
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 2)
        #expect(result[0].isBullet)
        #expect(result[0].text == "First item")
        #expect(result[1].isBullet)
        #expect(result[1].text == "Second item")
    }

    @Test("Bullet points with dash are converted")
    func dashBullets() {
        let text = "Intro:\n- First item\n- Second item"
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 3)
        #expect(result[1].isBullet)
        #expect(result[1].text == "First item")
        #expect(result[2].isBullet)
        #expect(result[2].text == "Second item")
    }

    @Test("Bullet text is trimmed")
    func bulletTextTrimmed() {
        let text = "•   Extra spaces   "
        let result = SummarizationTextFormatter.format(text)
        #expect(result[0].text == "Extra spaces")
    }
}

// MARK: - Heading Tests

@Suite("SummarizationTextFormatter Headings")
struct SummarizationTextFormatterHeadingTests {
    @Test("Markdown bold headings are parsed")
    func markdownBoldHeading() {
        let text = "**Key Points**\nSome content here."
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 2)
        #expect(result[0].isHeading)
        #expect(result[0].text == "Key Points")
        #expect(!result[1].isHeading)
    }

    @Test("Short text ending with colon is heading")
    func colonHeading() {
        let text = "Summary:\nThe main points are listed below."
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 2)
        #expect(result[0].isHeading)
        #expect(result[0].text == "Summary:")
    }

    @Test("Long text ending with colon is not heading")
    func longColonNotHeading() {
        let text = "This is a very long sentence that happens to end with a colon:"
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 1)
        #expect(!result[0].isHeading)
    }

    @Test("Text with period and colon is not heading")
    func periodAndColonNotHeading() {
        let text = "Dr. Smith says:"
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 1)
        #expect(!result[0].isHeading)
    }

    @Test("Text with too many words is not heading")
    func tooManyWordsNotHeading() {
        let text = "One two three four five six:"
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 1)
        #expect(!result[0].isHeading)
    }

    @Test("Five words ending with colon is heading")
    func fiveWordsIsHeading() {
        let text = "One two three four five:"
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 1)
        #expect(result[0].isHeading)
    }
}

// MARK: - Edge Case Tests

@Suite("SummarizationTextFormatter Edge Cases")
struct SummarizationTextFormatterEdgeCaseTests {
    @Test("Abbreviations are preserved")
    func abbreviationsPreserved() {
        let text = "Dr. Smith met with U.S. officials."
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 1)
        #expect(result[0].text == "Dr. Smith met with U.S. officials.")
    }

    @Test("URLs in text are preserved")
    func urlsPreserved() {
        let text = "Visit https://example.com for more info."
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 1)
        #expect(result[0].text.contains("https://example.com"))
    }

    @Test("Mixed content formatting")
    func mixedContent() {
        let text = """
        **Overview**
        This article covers important topics.
        Key Points:
        - First point
        - Second point
        Conclusion here.
        """
        let result = SummarizationTextFormatter.format(text)
        #expect(result.count == 6)
        #expect(result[0].isHeading) // **Overview**
        #expect(!result[1].isHeading) // This article...
        #expect(result[2].isHeading) // Key Points:
        #expect(result[3].isBullet) // First point
        #expect(result[4].isBullet) // Second point
        #expect(!result[5].isHeading) // Conclusion
    }

    @Test("Sentence ending with colon in middle is not heading")
    func sentenceWithColonNotHeading() {
        let text = "Here's what you need to know. The features are:"
        let result = SummarizationTextFormatter.format(text)
        // This should be one paragraph since there's no newline
        #expect(result.count == 1)
        #expect(!result[0].isHeading)
    }

    @Test("FormattedParagraph equality ignores id")
    func paragraphEquality() {
        let paragraph1 = FormattedParagraph(text: "Test", isHeading: true, isBullet: false)
        let paragraph2 = FormattedParagraph(text: "Test", isHeading: true, isBullet: false)
        #expect(paragraph1 == paragraph2)
    }
}
