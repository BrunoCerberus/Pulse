//
//  PaywallDomainInteractor.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Combine
import Foundation
import StoreKit

/// Domain interactor for the Paywall feature business logic.
///
/// This interactor handles all business logic for the Paywall feature using Clean Architecture principles.
/// It processes domain actions and manages domain state while communicating with StoreKit services.
@MainActor
final class PaywallDomainInteractor: CombineInteractor {
    // MARK: - CombineInteractor Requirements

    typealias DomainState = PaywallDomainState
    typealias DomainAction = PaywallDomainAction

    var statePublisher: AnyPublisher<PaywallDomainState, Never> {
        currentStateSubject.eraseToAnyPublisher()
    }

    // MARK: - Properties

    private let currentStateSubject: CurrentValueSubject<PaywallDomainState, Never>
    private let storeKitService: StoreKitService
    private var cancellables: Set<AnyCancellable> = []

    var currentState: PaywallDomainState {
        currentStateSubject.value
    }

    // MARK: - Initialization

    init(
        serviceLocator: ServiceLocator,
        initialState: PaywallDomainState = .initial
    ) {
        currentStateSubject = CurrentValueSubject(initialState)

        do {
            storeKitService = try serviceLocator.retrieve(StoreKitService.self)
        } catch {
            Logger.shared.service("Failed to retrieve StoreKitService: \(error)", level: .warning)
            storeKitService = LiveStoreKitService()
        }

        observeSubscriptionStatus()
    }

    // MARK: - CombineInteractor Implementation

    func dispatch(action: PaywallDomainAction) {
        switch action {
        case .loadProducts:
            handleLoadProducts()

        case let .selectProduct(product):
            handleSelectProduct(product)

        case let .purchase(product):
            handlePurchase(product)

        case .restorePurchases:
            handleRestorePurchases()

        case .dismiss:
            handleDismiss()

        case .checkSubscriptionStatus:
            handleCheckSubscriptionStatus()
        }
    }

    // MARK: - Private Action Handlers

    private func handleLoadProducts() {
        updateState(currentState.copy(isLoadingProducts: true, error: nil))

        storeKitService.fetchProducts()
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case let .failure(error) = completion {
                        updateState(currentState.copy(
                            isLoadingProducts: false,
                            error: error.localizedDescription
                        ))
                    }
                },
                receiveValue: { [weak self] products in
                    guard let self else { return }
                    updateState(currentState.copy(
                        products: products,
                        isLoadingProducts: false
                    ))
                }
            )
            .store(in: &cancellables)
    }

    private func handleSelectProduct(_ product: Product) {
        updateState(currentState.copy(selectedProduct: product))
    }

    private func handlePurchase(_ product: Product) {
        updateState(currentState.copy(isPurchasing: true, error: nil))

        storeKitService.purchase(product)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case let .failure(error) = completion {
                        updateState(currentState.copy(
                            isPurchasing: false,
                            error: error.localizedDescription
                        ))
                    }
                },
                receiveValue: { [weak self] success in
                    guard let self else { return }
                    updateState(currentState.copy(
                        isPremium: success,
                        isPurchasing: false,
                        purchaseSuccessful: success,
                        shouldDismiss: success
                    ))
                }
            )
            .store(in: &cancellables)
    }

    private func handleRestorePurchases() {
        updateState(currentState.copy(isRestoring: true, error: nil))

        storeKitService.restorePurchases()
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self else { return }
                    if case let .failure(error) = completion {
                        updateState(currentState.copy(
                            isRestoring: false,
                            error: error.localizedDescription
                        ))
                    }
                },
                receiveValue: { [weak self] hasPurchases in
                    guard let self else { return }
                    updateState(currentState.copy(
                        isPremium: hasPurchases,
                        isRestoring: false,
                        restoreSuccessful: true,
                        shouldDismiss: hasPurchases
                    ))
                }
            )
            .store(in: &cancellables)
    }

    private func handleDismiss() {
        updateState(currentState.copy(shouldDismiss: true))
    }

    private func handleCheckSubscriptionStatus() {
        storeKitService.checkSubscriptionStatus()
            .sink { [weak self] isPremium in
                guard let self else { return }
                updateState(currentState.copy(
                    isPremium: isPremium,
                    shouldDismiss: isPremium
                ))
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Helper Methods

    private func observeSubscriptionStatus() {
        storeKitService.subscriptionStatusPublisher
            .sink { [weak self] isPremium in
                guard let self else { return }
                updateState(currentState.copy(isPremium: isPremium))
            }
            .store(in: &cancellables)
    }

    private func updateState(_ newState: PaywallDomainState) {
        currentStateSubject.send(newState)
    }
}
