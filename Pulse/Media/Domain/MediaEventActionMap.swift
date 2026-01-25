import EntropyCore
import Foundation

/// Maps view events to domain actions for the Media feature.
///
/// This mapper decouples the view layer from domain logic,
/// allowing independent testing of each layer.
struct MediaEventActionMap: DomainEventActionMap {
    func map(event: MediaViewEvent) -> MediaDomainAction? {
        switch event {
        case .onAppear:
            return .loadInitialData
        case .onRefresh:
            return .refresh
        case .onLoadMore:
            return .loadMoreMedia
        case let .onMediaTypeSelected(type):
            return .selectMediaType(type)
        case let .onMediaTapped(mediaId):
            return .selectMedia(mediaId: mediaId)
        case .onMediaNavigated:
            return .clearSelectedMedia
        case let .onShareTapped(mediaId):
            return .shareMedia(mediaId: mediaId)
        case .onShareDismissed:
            return .clearMediaToShare
        case let .onPlayTapped(mediaId):
            return .playMedia(mediaId: mediaId)
        case .onPlayDismissed:
            return .clearMediaToPlay
        }
    }
}
