import Foundation

struct ArticleDetailEventActionMap: DomainEventActionMap {
    func map(event: ArticleDetailViewEvent) -> ArticleDetailDomainAction? {
        switch event {
        case .onAppear:
            return .onAppear
        case .onBookmarkTapped:
            return .toggleBookmark
        case .onShareTapped:
            return .showShareSheet
        case .onSummarizeTapped:
            return .showSummarizationSheet
        case .onReadFullTapped:
            return .openInBrowser
        case .onShareSheetDismissed:
            return .dismissShareSheet
        case .onSummarizationSheetDismissed:
            return .dismissSummarizationSheet
        }
    }
}
