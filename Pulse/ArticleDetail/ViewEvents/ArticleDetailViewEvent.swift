import Foundation

enum ArticleDetailViewEvent: Equatable {
    /// Lifecycle
    case onAppear
    case onDisappear

    // Toolbar actions
    case onBookmarkTapped
    case onShareTapped
    case onSummarizeTapped

    /// Content
    case onReadFullTapped

    // Sheet management
    case onShareSheetDismissed
    case onSummarizationSheetDismissed

    // Text-to-Speech
    case onListenTapped
    case onTTSPlayPauseTapped
    case onTTSStopTapped
    case onTTSSpeedTapped
}
