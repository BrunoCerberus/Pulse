//
//  PaywallViewModel.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Combine
import Foundation
import StoreKit

/// ViewModel for the Paywall screen using Clean Architecture principles.
///
/// This ViewModel follows Clean Architecture by:
/// - Using CombineViewModel protocol
/// - Having a single source of truth through viewState
/// - Delegating business logic to PaywallDomainInteractor
/// - Converting view events to domain actions
/// - Converting domain state to view state
@MainActor
final class PaywallViewModel: ObservableObject, CombineViewModel {
    // MARK: - CombineViewModel Requirements

    typealias ViewState = PaywallViewState
    typealias ViewEvent = PaywallViewEvent

    /// Single source of truth for the view state.
    @Published var viewState: PaywallViewState = .loading

    // MARK: - Dependencies

    private let domainInteractor: PaywallDomainInteractor
    private let viewStateReducer: PaywallViewStateReducing
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        serviceLocator: ServiceLocator,
        domainInteractor: PaywallDomainInteractor? = nil,
        viewStateReducer: PaywallViewStateReducing? = nil
    ) {
        self.domainInteractor = domainInteractor ?? PaywallDomainInteractor(
            serviceLocator: serviceLocator
        )

        self.viewStateReducer = viewStateReducer ?? PaywallViewStateReducer()

        setupStateObservation()
    }

    // MARK: - CombineViewModel Implementation

    func handle(event: PaywallViewEvent) {
        let domainAction = PaywallDomainEventActionMap.map(event)
        domainInteractor.dispatch(action: domainAction)
    }

    // MARK: - Computed Properties from View State

    var products: [Product] {
        guard case let .success(dataViewState) = viewState else {
            return []
        }
        return dataViewState.products
    }

    var selectedProduct: Product? {
        guard case let .success(dataViewState) = viewState else {
            return nil
        }
        return dataViewState.selectedProduct
    }

    var isPremium: Bool {
        guard case let .success(dataViewState) = viewState else {
            return false
        }
        return dataViewState.isPremium
    }

    var isPurchasing: Bool {
        guard case let .success(dataViewState) = viewState else {
            return false
        }
        return dataViewState.isPurchasing
    }

    var isRestoring: Bool {
        guard case let .success(dataViewState) = viewState else {
            return false
        }
        return dataViewState.isRestoring
    }

    var shouldDismiss: Bool {
        guard case let .success(dataViewState) = viewState else {
            return false
        }
        return dataViewState.shouldDismiss
    }

    var isLoading: Bool {
        if case .loading = viewState {
            return true
        }
        return false
    }

    var error: String? {
        if case let .error(message) = viewState {
            return message
        }
        return nil
    }

    // MARK: - Private Methods

    private func setupStateObservation() {
        domainInteractor.statePublisher
            .map { [weak self] domainState in
                self?.viewStateReducer.reduce(domainState) ?? .loading
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }

    deinit {
        Logger.shared.viewModel("PaywallViewModel deallocated", level: .debug)
    }
}
