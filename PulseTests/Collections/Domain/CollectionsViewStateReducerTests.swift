import EntropyCore
import Foundation
@testable import Pulse
import Testing

/// Tests for CollectionsViewStateReducer covering:
/// - Collection transformation to view items
/// - Loading and refreshing states
/// - Error message mapping
/// - Empty state detection
/// - Selected collection mapping
/// - Create sheet state
/// - Delete confirmation state
@Suite("CollectionsViewStateReducer Tests")
@MainActor
struct CollectionsViewStateReducerTests {
    let sut: CollectionsViewStateReducer

    init() {
        sut = CollectionsViewStateReducer()
    }

    // MARK: - Initial State Tests

    @Test("Reduces initial domain state correctly")
    func reducesInitialDomainState() {
        let domainState = CollectionsDomainState.initial

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.featuredCollections.isEmpty)
        #expect(viewState.userCollections.isEmpty)
        #expect(!viewState.isLoading)
        #expect(!viewState.isRefreshing)
        #expect(viewState.errorMessage == nil)
        #expect(!viewState.showEmptyState)
        #expect(!viewState.showCreateSheet)
        #expect(viewState.selectedCollection == nil)
        #expect(viewState.collectionToDelete == nil)
    }

    // MARK: - Loading State Tests

    @Test("Reduces loading state correctly")
    func reducesLoadingState() {
        var domainState = CollectionsDomainState.initial
        domainState.isLoading = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isLoading)
        #expect(!viewState.showEmptyState)
    }

    @Test("Reduces refreshing state correctly")
    func reducesRefreshingState() {
        var domainState = CollectionsDomainState.initial
        domainState.isRefreshing = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.isRefreshing)
        #expect(!viewState.showEmptyState)
    }

    // MARK: - Collection Transformation Tests

    @Test("Transforms featured collections to view items")
    func transformsFeaturedCollections() {
        var domainState = CollectionsDomainState.initial
        domainState.featuredCollections = Collection.sampleFeatured
        domainState.hasLoadedInitialData = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.featuredCollections.count == Collection.sampleFeatured.count)
        #expect(viewState.featuredCollections.first?.id == Collection.sampleFeatured.first?.id)
        #expect(viewState.featuredCollections.first?.name == Collection.sampleFeatured.first?.name)
    }

    @Test("Transforms user collections to view items")
    func transformsUserCollections() {
        var domainState = CollectionsDomainState.initial
        domainState.userCollections = Collection.sampleUser
        domainState.hasLoadedInitialData = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.userCollections.count == Collection.sampleUser.count)
        #expect(viewState.userCollections.first?.id == Collection.sampleUser.first?.id)
    }

    // MARK: - Error State Tests

    @Test("Reduces error message correctly")
    func reducesErrorMessage() {
        var domainState = CollectionsDomainState.initial
        domainState.error = "Network error occurred"

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.errorMessage == "Network error occurred")
    }

    @Test("Nil error when no error in domain")
    func nilErrorWhenNoError() {
        let domainState = CollectionsDomainState.initial

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.errorMessage == nil)
    }

    // MARK: - Empty State Tests

    @Test("Shows empty state when no collections after loading")
    func showsEmptyStateWhenNoCollections() {
        var domainState = CollectionsDomainState.initial
        domainState.hasLoadedInitialData = true
        domainState.featuredCollections = []
        domainState.userCollections = []

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.showEmptyState)
    }

    @Test("Does not show empty state when loading")
    func doesNotShowEmptyStateWhenLoading() {
        var domainState = CollectionsDomainState.initial
        domainState.isLoading = true
        domainState.featuredCollections = []
        domainState.userCollections = []

        let viewState = sut.reduce(domainState: domainState)

        #expect(!viewState.showEmptyState)
    }

    @Test("Does not show empty state when refreshing")
    func doesNotShowEmptyStateWhenRefreshing() {
        var domainState = CollectionsDomainState.initial
        domainState.isRefreshing = true
        domainState.hasLoadedInitialData = true
        domainState.featuredCollections = []
        domainState.userCollections = []

        let viewState = sut.reduce(domainState: domainState)

        #expect(!viewState.showEmptyState)
    }

    @Test("Does not show empty state before initial load")
    func doesNotShowEmptyStateBeforeInitialLoad() {
        var domainState = CollectionsDomainState.initial
        domainState.hasLoadedInitialData = false
        domainState.featuredCollections = []
        domainState.userCollections = []

        let viewState = sut.reduce(domainState: domainState)

        #expect(!viewState.showEmptyState)
    }

    @Test("Does not show empty state when has featured collections")
    func doesNotShowEmptyStateWithFeaturedCollections() {
        var domainState = CollectionsDomainState.initial
        domainState.hasLoadedInitialData = true
        domainState.featuredCollections = Collection.sampleFeatured
        domainState.userCollections = []

        let viewState = sut.reduce(domainState: domainState)

        #expect(!viewState.showEmptyState)
    }

    @Test("Does not show empty state when has user collections")
    func doesNotShowEmptyStateWithUserCollections() {
        var domainState = CollectionsDomainState.initial
        domainState.hasLoadedInitialData = true
        domainState.featuredCollections = []
        domainState.userCollections = Collection.sampleUser

        let viewState = sut.reduce(domainState: domainState)

        #expect(!viewState.showEmptyState)
    }

    // MARK: - Empty User Collections Tests

    @Test("Shows empty user collections when only featured exist")
    func showsEmptyUserCollections() {
        var domainState = CollectionsDomainState.initial
        domainState.hasLoadedInitialData = true
        domainState.featuredCollections = Collection.sampleFeatured
        domainState.userCollections = []

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.showEmptyUserCollections)
    }

    @Test("Does not show empty user collections when has user collections")
    func doesNotShowEmptyUserCollections() {
        var domainState = CollectionsDomainState.initial
        domainState.hasLoadedInitialData = true
        domainState.featuredCollections = Collection.sampleFeatured
        domainState.userCollections = Collection.sampleUser

        let viewState = sut.reduce(domainState: domainState)

        #expect(!viewState.showEmptyUserCollections)
    }

    // MARK: - Selected Collection Tests

    @Test("Maps selected collection from domain state")
    func mapsSelectedCollection() {
        var domainState = CollectionsDomainState.initial
        domainState.selectedCollection = Collection.sampleFeatured.first

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.selectedCollection?.id == Collection.sampleFeatured.first?.id)
    }

    @Test("Nil selected collection when none in domain")
    func nilSelectedCollection() {
        var domainState = CollectionsDomainState.initial
        domainState.selectedCollection = nil

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.selectedCollection == nil)
    }

    // MARK: - Create Sheet Tests

    @Test("Maps show create sheet state")
    func mapsShowCreateSheet() {
        var domainState = CollectionsDomainState.initial
        domainState.showCreateSheet = true

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.showCreateSheet)
    }

    @Test("Maps hide create sheet state")
    func mapsHideCreateSheet() {
        var domainState = CollectionsDomainState.initial
        domainState.showCreateSheet = false

        let viewState = sut.reduce(domainState: domainState)

        #expect(!viewState.showCreateSheet)
    }

    // MARK: - Delete Confirmation Tests

    @Test("Maps collection to delete from domain state")
    func mapsCollectionToDelete() {
        var domainState = CollectionsDomainState.initial
        domainState.collectionToDelete = Collection.sampleUser.first

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.collectionToDelete?.id == Collection.sampleUser.first?.id)
    }

    @Test("Nil collection to delete when none in domain")
    func nilCollectionToDelete() {
        var domainState = CollectionsDomainState.initial
        domainState.collectionToDelete = nil

        let viewState = sut.reduce(domainState: domainState)

        #expect(viewState.collectionToDelete == nil)
    }
}
