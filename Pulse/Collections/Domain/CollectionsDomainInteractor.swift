import Combine
import EntropyCore
import Foundation

final class CollectionsDomainInteractor: CombineInteractor {
    typealias DomainState = CollectionsDomainState
    typealias DomainAction = CollectionsDomainAction

    private let collectionsService: CollectionsService
    private let stateSubject = CurrentValueSubject<CollectionsDomainState, Never>(.initial)
    private var cancellables = Set<AnyCancellable>()

    var statePublisher: AnyPublisher<CollectionsDomainState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var currentState: CollectionsDomainState {
        stateSubject.value
    }

    init(serviceLocator: ServiceLocator) {
        do {
            collectionsService = try serviceLocator.retrieve(CollectionsService.self)
        } catch {
            Logger.shared.service("Failed to retrieve CollectionsService: \(error)", level: .warning)
            collectionsService = MockCollectionsService.withSampleData()
        }
    }

    func dispatch(action: CollectionsDomainAction) {
        switch action {
        case .loadInitialData:
            loadInitialData()
        case .refresh:
            refresh()
        case let .selectCollection(collectionId):
            selectCollection(id: collectionId)
        case .clearSelectedCollection:
            clearSelectedCollection()
        case .showCreateCollectionSheet:
            showCreateSheet()
        case .hideCreateCollectionSheet:
            hideCreateSheet()
        case let .createCollection(name, description):
            createCollection(name: name, description: description)
        case let .deleteCollection(collectionId):
            prepareDeleteCollection(id: collectionId)
        case .confirmDeleteCollection:
            confirmDeleteCollection()
        case .cancelDeleteCollection:
            cancelDeleteCollection()
        case let .addArticleToCollection(article, collectionId):
            addArticleToCollection(article, collectionId: collectionId)
        case let .removeArticleFromCollection(articleId, collectionId):
            removeArticleFromCollection(articleId: articleId, collectionId: collectionId)
        case let .markArticleAsRead(articleId, collectionId):
            markArticleAsRead(articleId: articleId, collectionId: collectionId)
        }
    }

    private func loadInitialData() {
        guard !currentState.isLoading, !currentState.hasLoadedInitialData else { return }

        updateState { state in
            state.isLoading = true
            state.error = nil
        }

        Publishers.Zip(
            collectionsService.fetchFeaturedCollections(),
            collectionsService.fetchUserCollections()
        )
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.updateState { state in
                    state.isLoading = false
                    state.error = error.localizedDescription
                }
            }
        } receiveValue: { [weak self] featured, user in
            self?.updateState { state in
                state.featuredCollections = featured
                state.userCollections = user
                state.isLoading = false
                state.hasLoadedInitialData = true
            }
        }
        .store(in: &cancellables)
    }

    private func refresh() {
        updateState { state in
            state.isRefreshing = true
            state.error = nil
        }

        Publishers.Zip(
            collectionsService.fetchFeaturedCollections(),
            collectionsService.fetchUserCollections()
        )
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.updateState { state in
                    state.isRefreshing = false
                    state.error = error.localizedDescription
                }
            }
        } receiveValue: { [weak self] featured, user in
            self?.updateState { state in
                state.featuredCollections = featured
                state.userCollections = user
                state.isRefreshing = false
            }
        }
        .store(in: &cancellables)
    }

    private func selectCollection(id: String) {
        let collection = findCollection(by: id)
        updateState { state in
            state.selectedCollection = collection
        }
    }

    private func clearSelectedCollection() {
        updateState { state in
            state.selectedCollection = nil
        }
    }

    private func showCreateSheet() {
        updateState { state in
            state.showCreateSheet = true
        }
    }

    private func hideCreateSheet() {
        updateState { state in
            state.showCreateSheet = false
        }
    }

    private func createCollection(name: String, description: String) {
        collectionsService.createCollection(name: name, description: description)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] collection in
                self?.updateState { state in
                    state.userCollections.append(collection)
                    state.showCreateSheet = false
                }
            }
            .store(in: &cancellables)
    }

    private func prepareDeleteCollection(id: String) {
        guard let collection = findCollection(by: id) else { return }
        updateState { state in
            state.collectionToDelete = collection
        }
    }

    private func confirmDeleteCollection() {
        guard let collection = currentState.collectionToDelete else { return }

        collectionsService.deleteCollection(id: collection.id)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.error = error.localizedDescription
                        state.collectionToDelete = nil
                    }
                }
            } receiveValue: { [weak self] in
                self?.updateState { state in
                    state.userCollections.removeAll { $0.id == collection.id }
                    state.collectionToDelete = nil
                }
            }
            .store(in: &cancellables)
    }

    private func cancelDeleteCollection() {
        updateState { state in
            state.collectionToDelete = nil
        }
    }

    private func addArticleToCollection(_ article: Article, collectionId: String) {
        collectionsService.addArticleToCollection(article, collectionID: collectionId)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] updatedCollection in
                self?.updateCollectionInState(updatedCollection)
            }
            .store(in: &cancellables)
    }

    private func removeArticleFromCollection(articleId: String, collectionId: String) {
        collectionsService.removeArticleFromCollection(articleID: articleId, collectionID: collectionId)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] updatedCollection in
                self?.updateCollectionInState(updatedCollection)
            }
            .store(in: &cancellables)
    }

    private func markArticleAsRead(articleId: String, collectionId: String) {
        collectionsService.markArticleAsRead(articleID: articleId, collectionID: collectionId)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.updateState { state in
                        state.error = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] updatedCollection in
                self?.updateCollectionInState(updatedCollection)
            }
            .store(in: &cancellables)
    }

    private func findCollection(by id: String) -> Collection? {
        currentState.featuredCollections.first { $0.id == id }
            ?? currentState.userCollections.first { $0.id == id }
    }

    private func updateCollectionInState(_ collection: Collection) {
        updateState { state in
            if let index = state.featuredCollections.firstIndex(where: { $0.id == collection.id }) {
                state.featuredCollections[index] = collection
            }
            if let index = state.userCollections.firstIndex(where: { $0.id == collection.id }) {
                state.userCollections[index] = collection
            }
            if state.selectedCollection?.id == collection.id {
                state.selectedCollection = collection
            }
        }
    }

    private func updateState(_ transform: (inout CollectionsDomainState) -> Void) {
        var state = stateSubject.value
        transform(&state)
        stateSubject.send(state)
    }
}
