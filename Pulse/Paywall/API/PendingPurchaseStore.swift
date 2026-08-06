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
/// The pending purchase only ever answers for a scan that found *nothing*; it expires on the
/// transaction's own `expirationDate`, and a revocation of that transaction drops it. So it cannot
/// mask a lapsed or refunded subscription.
final class PendingPurchaseStore: @unchecked Sendable {
    private struct PendingPurchase {
        /// `nil` when the transaction carries no expiry.
        let expirationDate: Date?

        func isActive(at date: Date) -> Bool {
            guard let expirationDate else { return true }
            return expirationDate > date
        }
    }

    private let pending = OSAllocatedUnfairLock<PendingPurchase?>(initialState: nil)

    /// Records a transaction we verified ourselves. Ignores anything that isn't an auto-renewable
    /// subscription, matching what the entitlement scan looks for.
    ///
    /// A *revoked* transaction drops any record instead: a refund or chargeback arrives through
    /// `Transaction.updates` as the same transaction with `revocationDate` set, and by then it is
    /// already gone from `Transaction.currentEntitlements` — so nothing else would ever correct a
    /// record still holding the pre-refund `expirationDate`.
    func record(productType: Product.ProductType, revocationDate: Date?, expirationDate: Date?) {
        guard productType == .autoRenewable else { return }

        pending.withLock { pending in
            pending = revocationDate == nil ? PendingPurchase(expirationDate: expirationDate) : nil
        }
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
