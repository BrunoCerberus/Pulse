import Foundation
@testable import Pulse
import Testing

@Suite("SpeechTextBuilder Tests")
struct SpeechTextBuilderTests {
    private func makeArticle(
        title: String = "Test Title",
        description: String? = nil,
        content: String? = nil,
        author: String? = nil,
    ) -> Article {
        Article(
            title: title,
            description: description,
            content: content,
            author: author,
            source: ArticleSource(id: nil, name: "Test Source"),
            url: "https://example.com/article",
            publishedAt: Date(timeIntervalSince1970: 1_700_000_000),
        )
    }

    // MARK: - Article Speech Text

    @Test("article speech text joins title, author, description, and content")
    func articleSpeechTextComposition() {
        let article = makeArticle(
            description: "A description.",
            content: "Full content here.",
            author: "Jane Doe",
        )

        let text = SpeechTextBuilder.speechText(for: article)

        #expect(text.contains("Test Title"))
        // Resolved through AppLocalization (not hardcoded "By"): the runtime
        // language is whatever a previously-run test left persisted.
        #expect(text.contains(String(format: AppLocalization.localized("speech.by_author"), "Jane Doe")))
        #expect(text.contains("A description."))
        #expect(text.contains("Full content here."))
    }

    @Test("article speech text omits missing optional fields")
    func articleSpeechTextOmitsMissingFields() {
        let article = makeArticle()

        let text = SpeechTextBuilder.speechText(for: article)

        #expect(text == "Test Title")
    }

    @Test("article speech text strips HTML and entities")
    func articleSpeechTextStripsHTML() {
        let article = makeArticle(
            description: "<p>Hello &amp; <b>world</b></p>",
        )

        let text = SpeechTextBuilder.speechText(for: article)

        #expect(!text.contains("<p>"))
        #expect(!text.contains("&amp;"))
        #expect(text.contains("Hello & world"))
    }

    @Test("article speech text removes truncation markers")
    func articleSpeechTextStripsTruncationMarker() {
        let article = makeArticle(content: "Some content [+1234 chars]")

        let text = SpeechTextBuilder.speechText(for: article)

        #expect(!text.contains("chars]"))
        #expect(text.contains("Some content"))
    }

    @Test("article speech text filters scraper error phrases")
    func articleSpeechTextFiltersErrorContent() {
        let article = makeArticle(content: "Please disable your ad blocker")

        let text = SpeechTextBuilder.speechText(for: article)

        #expect(text == "Test Title")
    }

    // MARK: - Briefing Article Speech Text

    @Test("briefing speech text prepends a transition naming the source")
    func briefingSpeechTextHasTransition() {
        let article = makeArticle(description: "A description.")

        let text = SpeechTextBuilder.briefingSpeechText(for: article)

        #expect(text.contains(String(format: AppLocalization.localized("briefing.next_up_from"), "Test Source")))
        #expect(text.contains("Test Title"))
        #expect(text.contains("A description."))
    }

    @Test("plain article speech text never contains the briefing transition")
    func plainSpeechTextHasNoTransition() {
        let article = makeArticle()

        let text = SpeechTextBuilder.speechText(for: article)

        #expect(!text.contains(String(format: AppLocalization.localized("briefing.next_up_from"), "Test Source")))
    }

    // MARK: - Digest Speech Text

    @Test("digest speech text prepends the localized intro")
    func digestSpeechTextHasIntro() {
        let text = SpeechTextBuilder.speechText(forDigestSummary: "Today in tech.")

        #expect(text.contains("Today in tech."))
        #expect(text.count > "Today in tech.".count)
    }

    @Test("digest speech text strips markdown bold and headers")
    func digestSpeechTextStripsMarkdown() {
        let summary = """
        **Technology** Apple shipped a thing. *Emphasis* here.
        ## Header
        - bullet one
        * bullet two
        """

        let text = SpeechTextBuilder.speechText(forDigestSummary: summary)

        #expect(!text.contains("**"))
        #expect(!text.contains("##"))
        #expect(text.contains("Technology"))
        #expect(text.contains("Apple shipped a thing."))
        #expect(text.contains("Emphasis"))
        #expect(text.contains("bullet one"))
        #expect(!text.contains("- bullet"))
    }

    @Test("digest speech text with empty summary returns just the intro")
    func digestSpeechTextEmptySummary() {
        let text = SpeechTextBuilder.speechText(forDigestSummary: "   ")

        #expect(!text.isEmpty)
        #expect(!text.contains("\n\n"))
    }

    // MARK: - PlaybackItem Factories

    @Test("article factory snapshots narration text and language")
    func articleFactory() {
        let article = makeArticle(description: "Desc.")

        let item = PlaybackItem.article(article, language: "pt")

        #expect(item.id == article.id)
        #expect(item.title == article.title)
        #expect(item.sourceName == "Test Source")
        #expect(item.language == "pt")
        #expect(item.speechText.contains("Desc."))
        if case let .article(stored) = item.kind {
            #expect(stored == article)
        } else {
            Issue.record("Expected .article kind")
        }
    }

    @Test("briefingArticle factory prepends the transition; article factory does not")
    func briefingArticleFactoryAddsTransition() {
        let article = makeArticle(description: "Desc.")

        let plainItem = PlaybackItem.article(article, language: "en")
        let briefingItem = PlaybackItem.briefingArticle(article, language: "en")

        let transition = String(format: AppLocalization.localized("briefing.next_up_from"), "Test Source")
        #expect(!plainItem.speechText.contains(transition))
        #expect(briefingItem.speechText.contains(transition))
        #expect(briefingItem.id == article.id)
        #expect(briefingItem.language == "en")
    }
}
