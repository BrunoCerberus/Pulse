import Combine
import EntropyCore
import Foundation

/// Domain interactor for the Media feature.
///
/// Manages business logic and state for the media feed, including:
/// - Loading featured media carousel and media items
/// - Infinite scroll pagination
/// - Pull-to-refresh
/// - Media type filtering (Videos/Podcasts/All)
/// - Media selection and sharing
///
/// ## Data Flow
/// 1. Views dispatch `MediaDomainAction` via `dispatch(action:)`
/// 2. Interactor processes actions and updates `MediaDomainState`
/// 3. State changes are published via `statePublisher`
///
/// ## Dependencies
/// - `MediaService`: Fetches media content from Supabase
@MainActor
final class MediaDomainInteractor: CombineInteractor {
    typealias DomainState = MediaDomainState
    typealias DomainAction = MediaDomainAction

    private let mediaService: MediaService
    private let stateSubject = CurrentValueSubject<MediaDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<MediaDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: MediaDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            mediaService = try serviceLocator.retrieve(MediaService.self)
        } catch {
            Logger.shared.service("Failed to retrieve MediaService: \(error)", level: .warning)
            mediaService = LiveMediaService()
        }
    }

    func dispatch(action: MediaDomainAction) {
        switch action {
        case .loadInitialData:
            loadInitialData()
        case .loadMoreMedia:
            loadMoreMedia()
        case .refresh:
            refresh()
        case let .selectMediaType(type):
            handleSelectMediaType(type)
        case let .selectMedia(mediaId):
            findMedia(by: mediaId).map { selectMedia($0) }
        case .clearSelectedMedia:
            clearSelectedMedia()
        case let .shareMedia(mediaId):
            findMedia(by: mediaId).map { shareMedia($0) }
        case .clearMediaToShare:
            clearMediaToShare()
        case let .playMedia(mediaId):
            findMedia(by: mediaId).map { playMedia($0) }
        case .clearMediaToPlay:
            clearMediaToPlay()
        }
    }

    private func findMedia(by id: String) -> Article? {
        currentState.featuredMedia.first { $0.id == id }
            ?? currentState.mediaItems.first { $0.id == id }
    }

    private func loadInitialData() {
        guard !currentState.isLoading, !currentState.hasLoadedInitialData else { return }

        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        let selectedType = currentState.selectedType

        // Fetch both featured media and first page of media items
        Publishers.Zip(
            mediaService.fetchFeaturedMedia(type: selectedType),
            mediaService.fetchMedia(type: selectedType, page: 1)
        )
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.updateState { state in
                    state.isLoading = false
                    state.error = error.localizedDescription
                }
            }
        } receiveValue: { [weak self] featured, media in
            self?.updateState { state in
                state.featuredMedia = featured
                state.mediaItems = self?.deduplicateMedia(media, excluding: featured) ?? media
                state.isLoading = false
                state.currentPage = 1
                state.hasMorePages = media.count >= 20
                state.hasLoadedInitialData = true
            }
        }
        .store(in: &cancellables)
    }

    private func loadMoreMedia() {
        guard !currentState.isLoadingMore, currentState.hasMorePages else { return }

        updateState { state in
            state.isLoadingMore = true
        }

        let nextPage = currentState.currentPage + 1
        let selectedType = currentState.selectedType

        mediaService.fetchMedia(type: selectedType, page: nextPage)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.updateState { state in
                        state.isLoadingMore = false
                    }
                }
            } receiveValue: { [weak self] media in
                guard let self else { return }
                self.updateState { state in
                    let existingIDs = Set(state.mediaItems.map { $0.id } + state.featuredMedia.map { $0.id })
                    let newMedia = media.filter { !existingIDs.contains($0.id) }
                    state.mediaItems.append(contentsOf: newMedia)
                    state.isLoadingMore = false
                    state.currentPage = nextPage
                    state.hasMorePages = media.count >= 20
                }
            }
            .store(in: &cancellables)
    }

    private func refresh() {
        updateState { state in
            state.isRefreshing = true
            state.featuredMedia = []
            state.mediaItems = []
            state.error = nil
            state.currentPage = 1
            state.hasMorePages = true
            state.hasLoadedInitialData = false
        }

        let selectedType = currentState.selectedType

        Publishers.Zip(
            mediaService.fetchFeaturedMedia(type: selectedType),
            mediaService.fetchMedia(type: selectedType, page: 1)
        )
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.updateState { state in
                    state.isRefreshing = false
                    state.error = error.localizedDescription
                }
            }
        } receiveValue: { [weak self] featured, media in
            self?.updateState { state in
                state.featuredMedia = featured
                state.mediaItems = self?.deduplicateMedia(media, excluding: featured) ?? media
                state.isRefreshing = false
                state.currentPage = 1
                state.hasMorePages = media.count >= 20
                state.hasLoadedInitialData = true
            }
        }
        .store(in: &cancellables)
    }

    private func handleSelectMediaType(_ type: MediaType?) {
        // Skip if already on this type
        guard type != currentState.selectedType else { return }

        updateState { state in
            state.selectedType = type
            state.mediaItems = []
            state.featuredMedia = []
            state.currentPage = 1
            state.hasMorePages = true
            state.hasLoadedInitialData = false
            state.isLoading = true
            state.error = nil
        }

        // Fetch both featured media and first page of media items for new type
        Publishers.Zip(
            mediaService.fetchFeaturedMedia(type: type),
            mediaService.fetchMedia(type: type, page: 1)
        )
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.updateState { state in
                    state.isLoading = false
                    state.error = error.localizedDescription
                }
            }
        } receiveValue: { [weak self] featured, media in
            self?.updateState { state in
                state.featuredMedia = featured
                state.mediaItems = self?.deduplicateMedia(media, excluding: featured) ?? media
                state.isLoading = false
                state.currentPage = 1
                state.hasMorePages = media.count >= 20
                state.hasLoadedInitialData = true
            }
        }
        .store(in: &cancellables)
    }

    private func selectMedia(_ media: Article) {
        updateState { state in
            state.selectedMedia = media
        }
    }

    private func clearSelectedMedia() {
        updateState { state in
            state.selectedMedia = nil
        }
    }

    private func shareMedia(_ media: Article) {
        updateState { state in
            state.mediaToShare = media
        }
    }

    private func clearMediaToShare() {
        updateState { state in
            state.mediaToShare = nil
        }
    }

    private func playMedia(_ media: Article) {
        updateState { state in
            state.mediaToPlay = media
        }
    }

    private func clearMediaToPlay() {
        updateState { state in
            state.mediaToPlay = nil
        }
    }

    private func deduplicateMedia(_ media: [Article], excluding: [Article]) -> [Article] {
        let excludeIDs = Set(excluding.map { $0.id })
        return media.filter { !excludeIDs.contains($0.id) }
    }

    private func updateState(_ transform: (inout MediaDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
