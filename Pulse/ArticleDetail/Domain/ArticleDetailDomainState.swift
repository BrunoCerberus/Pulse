import Foundation

/// Represents the domain state for the Article Detail feature.
///
/// This state is owned by `ArticleDetailDomainInteractor` and published via `statePublisher`.
/// The detail view displays the full article content with support for bookmarking,
/// sharing, and AI summarization (Premium).
struct ArticleDetailDomainState: Equatable {
    /// The article being displayed.
    let article: Article

    // MARK: - Content Processing

    /// Indicates whether article content is being processed into AttributedString.
    var isProcessingContent: Bool

    /// Processed article body content as AttributedString (supports links, formatting).
    var processedContent: AttributedString?

    /// Processed article description as AttributedString.
    var processedDescription: AttributedString?

    // MARK: - User Actions

    /// Whether the article is bookmarked by the user.
    var isBookmarked: Bool

    /// Whether to show the native share sheet.
    var showShareSheet: Bool

    /// Whether to show the AI summarization sheet (Premium feature).
    var showSummarizationSheet: Bool

    // MARK: - Text-to-Speech

    /// Current TTS playback state.
    var ttsPlaybackState: TTSPlaybackState

    /// TTS speech progress (0.0 to 1.0).
    var ttsProgress: Double

    /// Current TTS speed preset.
    var ttsSpeedPreset: TTSSpeedPreset

    /// Whether the TTS player bar is visible.
    var isTTSPlayerVisible: Bool

    /// Creates the initial state for a given article.
    /// - Parameter article: The article to display.
    /// - Returns: Initial state with content processing in progress.
    static func initial(article: Article) -> ArticleDetailDomainState {
        ArticleDetailDomainState(
            article: article,
            isProcessingContent: true,
            processedContent: nil,
            processedDescription: nil,
            isBookmarked: false,
            showShareSheet: false,
            showSummarizationSheet: false,
            ttsPlaybackState: .idle,
            ttsProgress: 0.0,
            ttsSpeedPreset: .normal,
            isTTSPlayerVisible: false
        )
    }
}
