import Foundation
@testable import Pulse
import StoreKit
import Testing

@Suite("PaywallViewStateReducer Tests")
struct PaywallViewStateReducerTests {
    let sut = PaywallViewStateReducer()

    // MARK: - Error State Tests

    @Test("Reducer returns error state when domain has error")
    func errorState() {
        let errorMessage = "Something went wrong"
        var domainState = PaywallDomainState.initial
        domainState.error = errorMessage

        let viewState = sut.reduce(domainState)

        if case let .error(message) = viewState {
            #expect(message == errorMessage)
        } else {
            Issue.record("Expected error state, got \(viewState)")
        }
    }

    @Test("Error state takes priority over loading state")
    func errorPriorityOverLoading() {
        var domainState = PaywallDomainState.initial
        domainState.error = "Error message"
        domainState.isLoadingProducts = true

        let viewState = sut.reduce(domainState)

        if case .error = viewState {
            // Expected
        } else {
            Issue.record("Expected error state to take priority, got \(viewState)")
        }
    }

    // MARK: - Loading State Tests

    @Test("Reducer returns loading state when loading products")
    func loadingState() {
        var domainState = PaywallDomainState.initial
        domainState.isLoadingProducts = true

        let viewState = sut.reduce(domainState)

        #expect(viewState == .loading)
    }

    // MARK: - Success State Tests

    @Test("Reducer returns success state with correct data")
    func successState() {
        let domainState = PaywallDomainState.initial

        let viewState = sut.reduce(domainState)

        if case let .success(dataState) = viewState {
            #expect(dataState.products.isEmpty)
            #expect(dataState.selectedProduct == nil)
            #expect(dataState.isPremium == false)
            #expect(dataState.isPurchasing == false)
            #expect(dataState.isRestoring == false)
            #expect(dataState.purchaseSuccessful == false)
            #expect(dataState.restoreSuccessful == false)
            #expect(dataState.shouldDismiss == false)
        } else {
            Issue.record("Expected success state, got \(viewState)")
        }
    }

    @Test("Reducer maps isPremium correctly")
    func mapsIsPremium() {
        var domainState = PaywallDomainState.initial
        domainState.isPremium = true

        let viewState = sut.reduce(domainState)

        if case let .success(dataState) = viewState {
            #expect(dataState.isPremium == true)
        } else {
            Issue.record("Expected success state")
        }
    }

    @Test("Reducer maps isPurchasing correctly")
    func mapsIsPurchasing() {
        var domainState = PaywallDomainState.initial
        domainState.isPurchasing = true

        let viewState = sut.reduce(domainState)

        if case let .success(dataState) = viewState {
            #expect(dataState.isPurchasing == true)
        } else {
            Issue.record("Expected success state")
        }
    }

    @Test("Reducer maps isRestoring correctly")
    func mapsIsRestoring() {
        var domainState = PaywallDomainState.initial
        domainState.isRestoring = true

        let viewState = sut.reduce(domainState)

        if case let .success(dataState) = viewState {
            #expect(dataState.isRestoring == true)
        } else {
            Issue.record("Expected success state")
        }
    }

    @Test("Reducer maps purchaseSuccessful correctly")
    func mapsPurchaseSuccessful() {
        var domainState = PaywallDomainState.initial
        domainState.purchaseSuccessful = true

        let viewState = sut.reduce(domainState)

        if case let .success(dataState) = viewState {
            #expect(dataState.purchaseSuccessful == true)
        } else {
            Issue.record("Expected success state")
        }
    }

    @Test("Reducer maps restoreSuccessful correctly")
    func mapsRestoreSuccessful() {
        var domainState = PaywallDomainState.initial
        domainState.restoreSuccessful = true

        let viewState = sut.reduce(domainState)

        if case let .success(dataState) = viewState {
            #expect(dataState.restoreSuccessful == true)
        } else {
            Issue.record("Expected success state")
        }
    }

    @Test("Reducer maps shouldDismiss correctly")
    func mapsShouldDismiss() {
        var domainState = PaywallDomainState.initial
        domainState.shouldDismiss = true

        let viewState = sut.reduce(domainState)

        if case let .success(dataState) = viewState {
            #expect(dataState.shouldDismiss == true)
        } else {
            Issue.record("Expected success state")
        }
    }

    @Test("Reducer preserves all state in single transformation")
    func preservesAllState() {
        var domainState = PaywallDomainState.initial
        domainState.isPremium = true
        domainState.isPurchasing = false
        domainState.isRestoring = true
        domainState.purchaseSuccessful = true
        domainState.restoreSuccessful = false
        domainState.shouldDismiss = true

        let viewState = sut.reduce(domainState)

        if case let .success(dataState) = viewState {
            #expect(dataState.isPremium == true)
            #expect(dataState.isPurchasing == false)
            #expect(dataState.isRestoring == true)
            #expect(dataState.purchaseSuccessful == true)
            #expect(dataState.restoreSuccessful == false)
            #expect(dataState.shouldDismiss == true)
        } else {
            Issue.record("Expected success state")
        }
    }
}

// MARK: - PaywallDomainState Initial Tests

@Suite("PaywallDomainState Initial Tests")
struct PaywallDomainStateInitialTests {
    @Test("Initial state has correct default values")
    func initialState() {
        let state = PaywallDomainState.initial

        #expect(state.products.isEmpty)
        #expect(state.selectedProduct == nil)
        #expect(state.isPremium == false)
        #expect(state.isLoadingProducts == false)
        #expect(state.isPurchasing == false)
        #expect(state.isRestoring == false)
        #expect(state.error == nil)
        #expect(state.purchaseSuccessful == false)
        #expect(state.restoreSuccessful == false)
        #expect(state.shouldDismiss == false)
    }
}
