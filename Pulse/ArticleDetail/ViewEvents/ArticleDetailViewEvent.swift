import Foundation

enum ArticleDetailViewEvent: Equatable {
    /// Lifecycle
    case onAppear

    // Toolbar actions
    case onBookmarkTapped
    case onShareTapped
    case onSummarizeTapped

    /// Content
    case onReadFullTapped

    // Sheet management
    case onShareSheetDismissed
    case onSummarizationSheetDismissed
}
