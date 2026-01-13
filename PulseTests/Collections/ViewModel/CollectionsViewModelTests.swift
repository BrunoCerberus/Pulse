import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

/// Tests for CollectionsViewModel covering:
/// - Initial state and onAppear behavior
/// - Refresh functionality
/// - Collection selection and navigation
/// - Create and delete collection flows
/// - Empty state detection
/// - Error handling
/// - Publisher binding and state transformation
@Suite("CollectionsViewModel Tests")
@MainActor
struct CollectionsViewModelTests {
    let mockCollectionsService: MockCollectionsService
    let serviceLocator: ServiceLocator
    let sut: CollectionsViewModel

    init() {
        mockCollectionsService = MockCollectionsService()
        serviceLocator = ServiceLocator()

        serviceLocator.register(CollectionsService.self, instance: mockCollectionsService)

        sut = CollectionsViewModel(serviceLocator: serviceLocator)
    }

    @Test("Initial view state is correct")
    func initialViewState() async throws {
        try await waitForStateUpdate()

        let state = sut.viewState
        #expect(state.featuredCollections.isEmpty)
        #expect(state.userCollections.isEmpty)
        #expect(!state.isLoading)
        #expect(!state.isRefreshing)
        #expect(state.errorMessage == nil)
        #expect(state.selectedCollection == nil)
        #expect(!state.showCreateSheet)
        #expect(state.collectionToDelete == nil)
    }

    @Test("Handle onAppear triggers load")
    func testOnAppear() async throws {
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured
        mockCollectionsService.mockUserCollections = Collection.sampleUser

        var cancellables = Set<AnyCancellable>()
        var states: [CollectionsViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .onAppear)

        let success = await waitForCondition { states.count > 1 }
        #expect(success)

        withExtendedLifetime(cancellables) {}
    }

    @Test("Handle onRefresh triggers refresh")
    func testOnRefresh() async throws {
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured

        var cancellables = Set<AnyCancellable>()
        var states: [CollectionsViewState] = []

        sut.$viewState
            .sink { state in
                states.append(state)
            }
            .store(in: &cancellables)

        sut.handle(event: .onRefresh)

        let success = await waitForCondition { states.count > 1 }
        #expect(success)

        withExtendedLifetime(cancellables) {}
    }

    @Test("Handle collection tapped updates selected collection")
    func collectionTapped() async throws {
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let collectionId = Collection.sampleFeatured.first!.id
        sut.handle(event: .onCollectionTapped(collectionId: collectionId))
        try await waitForStateUpdate()

        #expect(sut.viewState.selectedCollection?.id == collectionId)
    }

    @Test("Handle collection navigated clears selection")
    func collectionNavigated() async throws {
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let collectionId = Collection.sampleFeatured.first!.id
        sut.handle(event: .onCollectionTapped(collectionId: collectionId))
        try await waitForStateUpdate()

        sut.handle(event: .onCollectionNavigated)
        try await waitForStateUpdate()

        #expect(sut.viewState.selectedCollection == nil)
    }

    @Test("Handle create collection tapped shows sheet")
    func createCollectionTapped() async throws {
        sut.handle(event: .onCreateCollectionTapped)
        try await waitForStateUpdate()

        #expect(sut.viewState.showCreateSheet)
    }

    @Test("Handle create collection dismissed hides sheet")
    func createCollectionDismissed() async throws {
        sut.handle(event: .onCreateCollectionTapped)
        try await waitForStateUpdate()

        sut.handle(event: .onCreateCollectionDismissed)
        try await waitForStateUpdate()

        #expect(!sut.viewState.showCreateSheet)
    }

    @Test("Handle create collection adds collection")
    func createCollection() async throws {
        sut.handle(event: .onCreateCollection(name: "New Collection", description: "Description"))

        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.viewState.userCollections.contains { $0.name == "New Collection" })
    }

    @Test("Handle delete collection tapped shows confirmation")
    func deleteCollectionTapped() async throws {
        mockCollectionsService.mockUserCollections = Collection.sampleUser
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let collectionId = Collection.sampleUser.first!.id
        sut.handle(event: .onDeleteCollectionTapped(collectionId: collectionId))
        try await waitForStateUpdate()

        #expect(sut.viewState.collectionToDelete?.id == collectionId)
    }

    @Test("Handle delete collection confirmed removes collection")
    func deleteCollectionConfirmed() async throws {
        mockCollectionsService.mockUserCollections = Collection.sampleUser
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let collectionId = Collection.sampleUser.first!.id
        sut.handle(event: .onDeleteCollectionTapped(collectionId: collectionId))
        try await waitForStateUpdate()

        sut.handle(event: .onDeleteCollectionConfirmed)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(!sut.viewState.userCollections.contains { $0.id == collectionId })
    }

    @Test("Handle delete collection cancelled clears confirmation")
    func deleteCollectionCancelled() async throws {
        mockCollectionsService.mockUserCollections = Collection.sampleUser
        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let collectionId = Collection.sampleUser.first!.id
        sut.handle(event: .onDeleteCollectionTapped(collectionId: collectionId))
        try await waitForStateUpdate()

        sut.handle(event: .onDeleteCollectionCancelled)
        try await waitForStateUpdate()

        #expect(sut.viewState.collectionToDelete == nil)
    }

    @Test("Empty state shown when no collections and loaded")
    func emptyState() async throws {
        mockCollectionsService.mockFeaturedCollections = []
        mockCollectionsService.mockUserCollections = []

        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.viewState.showEmptyState)
    }

    @Test("Empty user collections shown when only featured exist")
    func emptyUserCollections() async throws {
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured
        mockCollectionsService.mockUserCollections = []

        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.viewState.showEmptyUserCollections)
        #expect(!sut.viewState.showEmptyState)
    }

    @Test("Error message shown on failure")
    func testErrorMessage() async throws {
        mockCollectionsService.shouldFail = true

        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        #expect(sut.viewState.errorMessage != nil)
    }

    @Test("Loading state shown during load")
    func loadingState() async throws {
        mockCollectionsService.delay = 0.5
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured

        var cancellables = Set<AnyCancellable>()
        var loadingStates: [Bool] = []

        sut.$viewState
            .map(\.isLoading)
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)

        sut.handle(event: .onAppear)

        let success = await waitForCondition { loadingStates.contains(true) }
        #expect(success)

        withExtendedLifetime(cancellables) {}
    }

    @Test("Featured collections transformed to view items")
    func featuredCollectionsTransformed() async throws {
        mockCollectionsService.mockFeaturedCollections = Collection.sampleFeatured

        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let viewItems = sut.viewState.featuredCollections
        #expect(!viewItems.isEmpty)
        #expect(viewItems.first?.name == Collection.sampleFeatured.first?.name)
    }

    @Test("User collections transformed to view items")
    func userCollectionsTransformed() async throws {
        mockCollectionsService.mockUserCollections = Collection.sampleUser

        sut.handle(event: .onAppear)
        try await waitForStateUpdate(duration: TestWaitDuration.long)

        let viewItems = sut.viewState.userCollections
        #expect(!viewItems.isEmpty)
        #expect(viewItems.first?.name == Collection.sampleUser.first?.name)
    }
}
