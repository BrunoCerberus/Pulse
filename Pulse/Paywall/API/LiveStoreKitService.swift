//
//  LiveStoreKitService.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Combine
import Foundation
import StoreKit

/// Live implementation of StoreKitService using StoreKit 2.
///
/// This service handles all StoreKit operations including:
/// - Product fetching
/// - Purchase processing
/// - Subscription status management
/// - Transaction observation
final class LiveStoreKitService: StoreKitService {
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
    private var updateListenerTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()

    var subscriptionStatusPublisher: AnyPublisher<Bool, Never> {
        subscriptionStatusSubject.eraseToAnyPublisher()
    }

    var isPremium: Bool {
        subscriptionStatusSubject.value
    }

    // MARK: - Initialization

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - StoreKitService Implementation

    func fetchProducts() -> AnyPublisher<[Product], Error> {
        Future { promise in
            Task {
                do {
                    let products = try await Product.products(for: Self.productIdentifiers)
                    promise(.success(products.sorted { $0.price < $1.price }))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func purchase(_ product: Product) -> AnyPublisher<Bool, Error> {
        Future { [weak self] promise in
            Task {
                do {
                    let result = try await product.purchase()

                    switch result {
                    case let .success(verification):
                        let transaction = try self?.checkVerified(verification)
                        await transaction?.finish()
                        await self?.updateSubscriptionStatus()
                        promise(.success(true))

                    case .userCancelled:
                        promise(.success(false))

                    case .pending:
                        promise(.success(false))

                    @unknown default:
                        promise(.success(false))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func restorePurchases() -> AnyPublisher<Bool, Error> {
        Future { [weak self] promise in
            Task {
                do {
                    try await AppStore.sync()
                    await self?.updateSubscriptionStatus()
                    let isPremium = self?.isPremium ?? false
                    promise(.success(isPremium))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func checkSubscriptionStatus() -> AnyPublisher<Bool, Never> {
        Future { [weak self] promise in
            Task {
                await self?.updateSubscriptionStatus()
                promise(.success(self?.isPremium ?? false))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    await self?.updateSubscriptionStatus()
                    await transaction?.finish()
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

    @MainActor
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

        subscriptionStatusSubject.send(hasActiveSubscription)
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
