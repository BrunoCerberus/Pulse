//
//  LiveStoreKitService.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Combine
import EntropyCore
import Foundation
import StoreKit

/// Live implementation of StoreKitService using StoreKit 2.
///
/// This service handles all StoreKit operations including:
/// - Product fetching
/// - Purchase processing
/// - Subscription status management
/// - Transaction observation
final class LiveStoreKitService: StoreKitService, @unchecked Sendable {
    // MARK: - Product Configuration

    /// Product identifiers for the app's subscriptions.
    /// These should match the identifiers configured in App Store Connect.
    static let subscriptionGroupID = "premium_subscriptions"
    static let monthlyProductID = "com.bruno.Pulse.premium.monthly"
    static let yearlyProductID = "com.bruno.Pulse.premium.yearly"

    private static let productIdentifiers: Set<String> = [
        monthlyProductID,
        yearlyProductID,
    ]

    // MARK: - Properties

    private let subscriptionStatusSubject = CurrentValueSubject<Bool, Never>(false)
    private var updateListenerTask: Task<Void, Never>?
    private var initialStatusTask: Task<Void, Never>?
    private var isListening = true

    var subscriptionStatusPublisher: AnyPublisher<Bool, Never> {
        subscriptionStatusSubject.eraseToAnyPublisher()
    }

    var isPremium: Bool {
        subscriptionStatusSubject.value
    }

    // MARK: - Initialization

    init() {
        updateListenerTask = listenForTransactions()
        initialStatusTask = Task { [weak self] in
            await self?.updateSubscriptionStatus()
        }
    }

    deinit {
        isListening = false
        updateListenerTask?.cancel()
        initialStatusTask?.cancel()
    }

    // MARK: - StoreKitService Implementation

    func fetchProducts() -> AnyPublisher<[Product], Error> {
        Future { promise in
            let promise = UncheckedSendableBox(value: promise)
            Task {
                do {
                    let products = try await Product.products(for: Self.productIdentifiers)
                    promise.value(.success(products.sorted { $0.price < $1.price }))
                } catch {
                    promise.value(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func purchase(_ product: Product) -> AnyPublisher<Bool, Error> {
        let weakSelf = UncheckedSendableBox(value: WeakRef(self))
        return Future { promise in
            let promise = UncheckedSendableBox(value: promise)
            Task {
                do {
                    let result = try await product.purchase()

                    switch result {
                    case let .success(verification):
                        let transaction = try weakSelf.value.object?.checkVerified(verification)
                        await transaction?.finish()
                        await weakSelf.value.object?.updateSubscriptionStatus()
                        promise.value(.success(true))

                    case .userCancelled:
                        promise.value(.success(false))

                    case .pending:
                        promise.value(.success(false))

                    @unknown default:
                        promise.value(.success(false))
                    }
                } catch {
                    promise.value(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func restorePurchases() -> AnyPublisher<Bool, Error> {
        let weakSelf = UncheckedSendableBox(value: WeakRef(self))
        return Future { promise in
            let promise = UncheckedSendableBox(value: promise)
            Task {
                do {
                    try await AppStore.sync()
                    await weakSelf.value.object?.updateSubscriptionStatus()
                    let isPremium = weakSelf.value.object?.isPremium ?? false
                    promise.value(.success(isPremium))
                } catch {
                    promise.value(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func checkSubscriptionStatus() -> AnyPublisher<Bool, Never> {
        let weakSelf = UncheckedSendableBox(value: WeakRef(self))
        return Future { promise in
            let promise = UncheckedSendableBox(value: promise)
            Task {
                await weakSelf.value.object?.updateSubscriptionStatus()
                promise.value(.success(weakSelf.value.object?.isPremium ?? false))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            // Exit early if self is already deallocated
            guard self != nil else { return }

            for await result in Transaction.updates {
                // Check both cancellation and listening flag for proper cleanup
                guard !Task.isCancelled else { break }
                guard let self, self.isListening else { break }

                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    Logger.shared.error("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification

        case let .verified(safe):
            return safe
        }
    }

    private func updateSubscriptionStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productType == .autoRenewable {
                    hasActiveSubscription = transaction.revocationDate == nil
                    if hasActiveSubscription { break }
                }
            } catch {
                Logger.shared.error("Failed to verify entitlement: \(error)")
            }
        }

        let finalStatus = hasActiveSubscription
        await MainActor.run {
            subscriptionStatusSubject.send(finalStatus)
        }
    }
}

// MARK: - StoreKit Errors

enum StoreKitError: LocalizedError {
    case failedVerification
    case purchaseFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            "Transaction verification failed"
        case .purchaseFailed:
            "Purchase failed"
        case .unknown:
            "An unknown error occurred"
        }
    }
}
