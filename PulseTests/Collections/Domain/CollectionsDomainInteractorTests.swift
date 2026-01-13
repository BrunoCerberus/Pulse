import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

/// Tests for CollectionsDomainInteractor covering:
/// - Initial state
/// - Load initial data and refresh
/// - Collection selection and navigation
/// - Create, delete collection flows
/// - Article management in collections
/// - Error handling
@Suite("CollectionsDomainInteractor Tests")
@MainActor
struct CollectionsDomainInteractorTests {
    let mockCollectionsService: MockCollectionsService
    let serviceLocator: ServiceLocator
    let sut: CollectionsDomainInteractor

    init() {
        mockCollectionsService = MockCollectionsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(CollectionsService.self, instance: mockCollectionsService)

        sut = CollectionsDomainInteractor(serviceLocator: serviceLocator)
    }

    // MARK: - Initial State Tests

    @Test("Initial state is correct")
    func initialState() {
        let state = sut.currentState
        #expect(state.featuredCollections.isEmpty)
        #expect(state.userCollections.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isRefreshing)
        #expect(state.error == nil)
        #expect(!state.hasLoadedInitialData)
        #expect(state.selectedCollection == nil)
        #expect(!state.showCreateSheet)
        #expect(state.collectionToDelete == nil)
    }

    // MARK: - Load Initial Data Tests

    @Test("Load initial data fetches collections")
    func loadInitialDataFetchesCollections() async throws {
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured
        mockCollectionsService.mockUserCollections = Collection.sampleUser

        sut.dispatch(action: .loadInitialData)

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(!state.featuredCollections.isEmpty)
        #expect(!state.userCollections.isEmpty)
        #expect(state.hasLoadedInitialData)
        #expect(state.error == nil)
    }

    @Test("Load initial data sets loading state")
    func loadInitialDataSetsLoadingState() async throws {
        mockCollectionsService.delay = 0.5
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured

        var cancellables = Set<AnyCancellable>()
        var states: [CollectionsDomainState] = []

        sut.statePublisher
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .loadInitialData)

        let success = await waitForCondition { states.count >= 2 }
        #expect(success)

        // First state after dispatch should be loading
        #expect(states.contains { $0.isLoading })

        withExtendedLifetime(cancellables) {}
    }

    @Test("Load initial data handles error")
    func loadInitialDataHandlesError() async throws {
        mockCollectionsService.shouldFail = true

        sut.dispatch(action: .loadInitialData)

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let state = sut.currentState
        #expect(!state.isLoading)
        #expect(state.error != nil)
    }

    @Test("Load initial data skips if already loaded")
    func loadInitialDataSkipsIfAlreadyLoaded() async throws {
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured
        mockCollectionsService.mockUserCollections = Collection.sampleUser

        sut.dispatch(action: .loadInitialData)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let initialFeaturedCount = sut.currentState.featuredCollections.count

        // Clear mock data to verify it doesn't refetch
        mockCollectionsService.mockFeaturedCollections = []

        sut.dispatch(action: .loadInitialData)
        try await waitForStateUpdate()

        #expect(sut.currentState.featuredCollections.count == initialFeaturedCount)
    }

    // MARK: - Refresh Tests

    @Test("Refresh fetches collections")
    func refreshFetchesCollections() async throws {
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured
        mockCollectionsService.mockUserCollections = Collection.sampleUser

        sut.dispatch(action: .refresh)

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let state = sut.currentState
        #expect(!state.isRefreshing)
        #expect(!state.featuredCollections.isEmpty)
        #expect(state.error == nil)
    }

    @Test("Refresh sets refreshing state")
    func refreshSetsRefreshingState() async throws {
        mockCollectionsService.delay = 0.5
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured

        var cancellables = Set<AnyCancellable>()
        var states: [CollectionsDomainState] = []

        sut.statePublisher
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .refresh)

        let success = await waitForCondition { states.count >= 2 }
        #expect(success)

        #expect(states.contains { $0.isRefreshing })

        withExtendedLifetime(cancellables) {}
    }

    @Test("Refresh handles error")
    func refreshHandlesError() async throws {
        mockCollectionsService.shouldFail = true

        sut.dispatch(action: .refresh)

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let state = sut.currentState
        #expect(!state.isRefreshing)
        #expect(state.error != nil)
    }

    // MARK: - Selection Tests

    @Test("Select collection updates selected collection")
    func selectCollectionUpdatesSelectedCollection() async throws {
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured
        sut.dispatch(action: .loadInitialData)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let collectionId = Collection.sampleFeatured.first!.id
        sut.dispatch(action: .selectCollection(collectionId: collectionId))

        try await waitForStateUpdate()

        #expect(sut.currentState.selectedCollection?.id == collectionId)
    }

    @Test("Clear selected collection resets selection")
    func clearSelectedCollectionResetsSelection() async throws {
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured
        sut.dispatch(action: .loadInitialData)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let collectionId = Collection.sampleFeatured.first!.id
        sut.dispatch(action: .selectCollection(collectionId: collectionId))
        try await waitForStateUpdate()

        sut.dispatch(action: .clearSelectedCollection)
        try await waitForStateUpdate()

        #expect(sut.currentState.selectedCollection == nil)
    }

    // MARK: - Create Collection Tests

    @Test("Show create collection sheet updates state")
    func showCreateCollectionSheetUpdatesState() async throws {
        sut.dispatch(action: .showCreateCollectionSheet)

        try await waitForStateUpdate()

        #expect(sut.currentState.showCreateSheet)
    }

    @Test("Hide create collection sheet updates state")
    func hideCreateCollectionSheetUpdatesState() async throws {
        sut.dispatch(action: .showCreateCollectionSheet)
        try await waitForStateUpdate()

        sut.dispatch(action: .hideCreateCollectionSheet)
        try await waitForStateUpdate()

        #expect(!sut.currentState.showCreateSheet)
    }

    @Test("Create collection adds to user collections")
    func createCollectionAddsToUserCollections() async throws {
        sut.dispatch(action: .createCollection(name: "Test Collection", description: "Test Description"))

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let state = sut.currentState
        #expect(state.userCollections.contains { $0.name == "Test Collection" })
        #expect(!state.showCreateSheet)
    }

    @Test("Create collection handles error")
    func createCollectionHandlesError() async throws {
        mockCollectionsService.shouldFail = true

        sut.dispatch(action: .createCollection(name: "Test", description: "Test"))

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.currentState.error != nil)
    }

    // MARK: - Delete Collection Tests

    @Test("Delete collection prepares collection to delete")
    func deleteCollectionPreparesCollectionToDelete() async throws {
        mockCollectionsService.mockUserCollections = Collection.sampleUser
        sut.dispatch(action: .loadInitialData)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let collectionId = Collection.sampleUser.first!.id
        sut.dispatch(action: .deleteCollection(collectionId: collectionId))

        try await waitForStateUpdate()

        #expect(sut.currentState.collectionToDelete?.id == collectionId)
    }

    @Test("Confirm delete collection removes from user collections")
    func confirmDeleteCollectionRemovesFromUserCollections() async throws {
        mockCollectionsService.mockUserCollections = Collection.sampleUser
        sut.dispatch(action: .loadInitialData)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let collectionId = Collection.sampleUser.first!.id
        sut.dispatch(action: .deleteCollection(collectionId: collectionId))
        try await waitForStateUpdate()

        sut.dispatch(action: .confirmDeleteCollection)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let state = sut.currentState
        #expect(!state.userCollections.contains { $0.id == collectionId })
        #expect(state.collectionToDelete == nil)
    }

    @Test("Cancel delete collection clears collection to delete")
    func cancelDeleteCollectionClearsCollectionToDelete() async throws {
        mockCollectionsService.mockUserCollections = Collection.sampleUser
        sut.dispatch(action: .loadInitialData)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let collectionId = Collection.sampleUser.first!.id
        sut.dispatch(action: .deleteCollection(collectionId: collectionId))
        try await waitForStateUpdate()

        sut.dispatch(action: .cancelDeleteCollection)
        try await waitForStateUpdate()

        #expect(sut.currentState.collectionToDelete == nil)
    }

    // MARK: - Publisher Tests

    @Test("State publisher emits updates")
    func statePublisherEmitsUpdates() async throws {
        var cancellables = Set<AnyCancellable>()
        var stateUpdates: [CollectionsDomainState] = []

        sut.statePublisher
            .sink { state in
                stateUpdates.append(state)
            }
            .store(in: &cancellables)

        sut.dispatch(action: .showCreateCollectionSheet)
        sut.dispatch(action: .hideCreateCollectionSheet)

        let success = await waitForCondition { stateUpdates.count >= 3 }
        #expect(success)

        withExtendedLifetime(cancellables) {}
    }
}
