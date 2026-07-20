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
            .loadInitialData
        case .onRefresh:
            .refresh
        case .onLoadMore:
            .loadMoreMedia
        case let .onMediaTypeSelected(type):
            .selectMediaType(type)
        case let .onMediaTapped(mediaId):
            .selectMedia(mediaId: mediaId)
        case .onMediaNavigated:
            .clearSelectedMedia
        case let .onShareTapped(mediaId):
            .shareMedia(mediaId: mediaId)
        case .onShareDismissed:
            .clearMediaToShare
        case let .onPlayTapped(mediaId):
            .playMedia(mediaId: mediaId)
        case .onPlayDismissed:
            .clearMediaToPlay
        }
    }
}
