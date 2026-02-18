import Combine
import EntropyCore
import Foundation

// MARK: - Data Loading Helpers

/// Extension containing data loading and language helpers to reduce body length in MediaDomainInteractor.
extension MediaDomainInteractor {
    func deduplicateMedia(_ media: [Article], excluding: [Article]) -> [Article] {
        let excludeIDs = Set(excluding.map { $0.id })
        return media.filter { !excludeIDs.contains($0.id) }
    }

    func updateState(_ transform: (inout MediaDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }

    // MARK: - Language Preferences

    func loadPreferredLanguage() {
        settingsService.fetchPreferences()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        Logger.shared.service(
                            "MediaDomainInteractor: Failed to load preferences: \(error)",
                            level: .warning
                        )
                    }
                },
                receiveValue: { [weak self] preferences in
                    self?.preferredLanguage = preferences.preferredLanguage
                }
            )
            .store(in: &cancellables)
    }

    func checkLanguageChange() {
        let previousLanguage = preferredLanguage
        settingsService.fetchPreferences()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] preferences in
                    guard let self else { return }
                    self.preferredLanguage = preferences.preferredLanguage
                    guard previousLanguage != self.preferredLanguage else { return }
                    self.reloadMediaForLanguageChange()
                }
            )
            .store(in: &cancellables)
    }

    func reloadMediaForLanguageChange() {
        if let cachingService = mediaService as? CachingMediaService {
            cachingService.invalidateCache()
        }
        updateState { state in
            state.mediaItems = []
            state.featuredMedia = []
            state.currentPage = 1
            state.hasMorePages = true
            state.hasLoadedInitialData = false
            state.isLoading = true
            state.error = nil
        }
        let selectedType = currentState.selectedType
        let language = preferredLanguage
        Publishers.Zip(
            mediaService.fetchFeaturedMedia(type: selectedType, language: language),
            mediaService.fetchMedia(type: selectedType, language: language, page: 1)
        )
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.updateState { state in
                    state.isLoading = false
                    state.error = error.localizedDescription
                    state.isOfflineError = error.isOfflineError
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
                state.isOfflineError = false
            }
        }
        .store(in: &cancellables)
    }
}
