//
//  PendingPurchaseStore.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Foundation
import os
import StoreKit

/// Bridges the window between a purchase we verified ourselves and StoreKit reporting it in
/// `Transaction.currentEntitlements`.
///
/// StoreKit's entitlement view lags the purchase by a moment — routinely so in sandbox. The
/// entitlement scan that runs right after `purchase()` can therefore come back empty, which would
/// publish `isPremium == false` to every premium gate even though the purchase succeeded, leaving
/// the user locked out until something happened to re-check.
///
/// The pending purchase only ever answers for a scan that found *nothing*, and it expires on the
/// transaction's own `expirationDate`, so it cannot mask a revocation or a lapsed subscription.
final nonisolated class PendingPurchaseStore: @unchecked Sendable {
    private struct PendingPurchase {
        /// `nil` when the transaction carries no expiry.
        let expirationDate: Date?

        func isActive(at date: Date) -> Bool {
            guard let expirationDate else { return true }
            return expirationDate > date
        }
    }

    private let pending = OSAllocatedUnfairLock<PendingPurchase?>(initialState: nil)

    /// Records a transaction we verified ourselves. Ignores anything that isn't an active
    /// auto-renewable subscription, matching what the entitlement scan looks for.
    func record(productType: Product.ProductType, revocationDate: Date?, expirationDate: Date?) {
        guard productType == .autoRenewable, revocationDate == nil else { return }

        pending.withLock { $0 = PendingPurchase(expirationDate: expirationDate) }
    }

    /// Resolves the subscription status for an entitlement scan, vouching for a recorded purchase
    /// the scan hasn't caught up with yet. A scan that *did* find the subscription clears the
    /// record, as does an expired one.
    func resolve(scanFoundActiveSubscription: Bool, now: Date = Date()) -> Bool {
        guard !scanFoundActiveSubscription else {
            pending.withLock { $0 = nil }
            return true
        }

        return pending.withLock { pending in
            guard pending?.isActive(at: now) == true else {
                pending = nil
                return false
            }
            return true
        }
    }
}
