//
//  StoreKitService.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Combine
import Foundation
import StoreKit

/// Protocol defining the interface for StoreKit operations.
///
/// This protocol abstracts the StoreKit layer and provides a clean interface
/// for fetching products, handling purchases, and managing subscription state.
protocol StoreKitService {
    /// Publisher for subscription status changes.
    var subscriptionStatusPublisher: AnyPublisher<Bool, Never> { get }

    /// Current subscription status.
    var isPremium: Bool { get }

    /// Fetch available products.
    /// - Returns: Publisher emitting array of products or error.
    func fetchProducts() -> AnyPublisher<[Product], Error>

    /// Purchase a product.
    /// - Parameter product: The product to purchase.
    /// - Returns: Publisher emitting purchase result or error.
    func purchase(_ product: Product) -> AnyPublisher<Bool, Error>

    /// Restore previous purchases.
    /// - Returns: Publisher emitting restore result or error.
    func restorePurchases() -> AnyPublisher<Bool, Error>

    /// Check current subscription status.
    /// - Returns: Publisher emitting subscription status.
    func checkSubscriptionStatus() -> AnyPublisher<Bool, Never>

    /// Re-validates subscription status by re-reading StoreKit 2's
    /// `Transaction.currentEntitlements` rather than trusting the cached
    /// `isPremium` value. Use at `.task` / `.onAppear` / scene-foreground
    /// boundaries inside premium gates so a jailbroken device can't unlock
    /// premium features by mutating the in-memory cache.
    /// - Returns: The freshly-computed subscription status.
    func refreshSubscriptionStatus() async -> Bool
}
