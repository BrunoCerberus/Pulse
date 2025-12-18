//
//  PaywallViewState.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Foundation
import StoreKit

/// High-level UI state for the Paywall view.
enum PaywallViewState: Equatable {
    /// Data is currently loading.
    case loading
    /// Data loaded successfully with associated payload.
    case success(PaywallDataViewState)
    /// An error occurred with a message to display.
    case error(String)
}

/// Data view state for successful Paywall view state.
///
/// This contains all the data needed to render the Paywall view
/// when the view is in a success state.
struct PaywallDataViewState: Equatable {
    /// Available products for purchase.
    let products: [Product]

    /// Currently selected product.
    let selectedProduct: Product?

    /// Whether the user has an active subscription.
    let isPremium: Bool

    /// Whether a purchase is in progress.
    let isPurchasing: Bool

    /// Whether restore is in progress.
    let isRestoring: Bool

    /// Whether purchase was successful.
    let purchaseSuccessful: Bool

    /// Whether restore was successful.
    let restoreSuccessful: Bool

    /// Whether to dismiss the paywall.
    let shouldDismiss: Bool

    static func == (lhs: PaywallDataViewState, rhs: PaywallDataViewState) -> Bool {
        lhs.products.map(\.id) == rhs.products.map(\.id) &&
            lhs.selectedProduct?.id == rhs.selectedProduct?.id &&
            lhs.isPremium == rhs.isPremium &&
            lhs.isPurchasing == rhs.isPurchasing &&
            lhs.isRestoring == rhs.isRestoring &&
            lhs.purchaseSuccessful == rhs.purchaseSuccessful &&
            lhs.restoreSuccessful == rhs.restoreSuccessful &&
            lhs.shouldDismiss == rhs.shouldDismiss
    }
}
