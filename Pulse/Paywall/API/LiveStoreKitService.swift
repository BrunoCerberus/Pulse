//
//  LiveStoreKitService.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Combine
import EntropyCore
import Foundation
import os
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

    /// Coalescing guard for `updateSubscriptionStatus()` (M3). `isUpdating` marks a scan
    /// in flight; `needsRerun` records that a request arrived mid-scan so the in-flight scan
    /// reruns exactly once more. Concurrent invocations (e.g. `purchase()` + the
    /// `Transaction.updates` listener observing the same transaction) collapse into a single
    /// `Transaction.currentEntitlements` scan with deterministic final send ordering.
    private let entitlementScanState = OSAllocatedUnfairLock(initialState: EntitlementScanState())

    private struct EntitlementScanState {
        var isUpdating = false
        var needsRerun = false
    }

    var subscriptionStatusPublisher: AnyPublisher<Bool, Never> {
        subscriptionStatusSubject.eraseToAnyPublisher()
    }

    var isPremium: Bool {
        subscriptionStatusSubject.value
    }

    // MARK: - Initialization

    /// - Parameter startListening: When `false`, skips the transaction listener and initial
    ///   status check. Use `false` in unit tests to avoid hanging on `Transaction.updates`.
    init(startListening: Bool = true) {
        guard startListening else { return }
        updateListenerTask = listenForTransactions()
        initialStatusTask = Task { [weak self] in
            await self?.updateSubscriptionStatus()
        }
    }

    deinit {
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
                // Terminate cleanly once the task is cancelled (deinit) or self is gone.
                guard !Task.isCancelled, let self else { break }

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

    /// Refreshes `subscriptionStatusSubject` from the current entitlements.
    ///
    /// Coalesces concurrent invocations (M3): on a successful purchase both `purchase()` and
    /// the long-lived `Transaction.updates` listener call this for the same transaction. Rather
    /// than running two overlapping `Transaction.currentEntitlements` scans with nondeterministic
    /// send ordering, the first caller performs the scan while any caller arriving mid-scan only
    /// flags a rerun. The in-flight scan then reruns exactly once more, so the final published
    /// value always reflects the latest entitlements. `purchase()` does not block on this — it
    /// resolves its publisher immediately after kicking the refresh off.
    private func updateSubscriptionStatus() async {
        // If a scan is already running, flag a rerun and let the active scan absorb this request.
        let shouldStart = entitlementScanState.withLock { state -> Bool in
            if state.isUpdating {
                state.needsRerun = true
                return false
            }
            state.isUpdating = true
            return true
        }
        guard shouldStart else { return }

        while true {
            let finalStatus = await scanCurrentEntitlements()
            await MainActor.run {
                subscriptionStatusSubject.send(finalStatus)
            }

            // Exit unless a request arrived mid-scan, in which case rerun exactly once more.
            let shouldRerun = entitlementScanState.withLock { state -> Bool in
                if state.needsRerun {
                    state.needsRerun = false
                    return true
                }
                state.isUpdating = false
                return false
            }
            if !shouldRerun { break }
        }
    }

    /// Performs a single pass over `Transaction.currentEntitlements`, returning whether an
    /// active (non-revoked) auto-renewable subscription is present.
    private func scanCurrentEntitlements() async -> Bool {
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

        return hasActiveSubscription
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
