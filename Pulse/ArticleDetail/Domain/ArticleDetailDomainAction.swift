import Foundation

/// Actions that can be dispatched to the Article Detail domain interactor.
///
/// These actions manage article viewing, bookmarking, sharing,
/// and AI summarization functionality.
enum ArticleDetailDomainAction: Equatable {
    // MARK: - Lifecycle

    /// View appeared, load bookmark status and process article content.
    case onAppear

    // MARK: - Bookmark

    /// Toggle the bookmark status of the current article.
    /// Adds to bookmarks if not saved, removes if already saved.
    case toggleBookmark

    /// Bookmark status loaded from storage.
    /// - Parameter isBookmarked: `true` if the article is currently bookmarked.
    case bookmarkStatusLoaded(Bool)

    // MARK: - Share

    /// Show the system share sheet for the current article.
    case showShareSheet

    /// Dismiss the share sheet after sharing completes or is cancelled.
    case dismissShareSheet

    // MARK: - Browser

    /// Open the article's original URL in the system browser.
    case openInBrowser

    // MARK: - Content Processing

    /// Article content has been processed into attributed strings.
    /// - Parameters:
    ///   - content: The formatted article body content, or `nil` if unavailable.
    ///   - description: The formatted article description/excerpt, or `nil` if unavailable.
    case contentProcessingCompleted(content: AttributedString?, description: AttributedString?)

    // MARK: - Summarization

    /// Show the AI summarization sheet (Premium feature).
    case showSummarizationSheet

    /// Dismiss the summarization sheet.
    case dismissSummarizationSheet

    // MARK: - Text-to-Speech

    /// Start reading the article aloud.
    case startTTS

    /// Toggle between playing and paused TTS.
    case toggleTTSPlayback

    /// Stop TTS and dismiss the player bar.
    case stopTTS

    /// Cycle to the next TTS speed preset.
    case cycleTTSSpeed

    /// TTS playback state changed (from service publisher).
    case ttsPlaybackStateChanged(TTSPlaybackState)

    /// TTS progress updated (from service publisher).
    case ttsProgressUpdated(Double)

    // MARK: - Related Articles

    /// Related articles loaded successfully.
    case relatedArticlesLoaded([Article])
}
