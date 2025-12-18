//
//  PaywallDomainState.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Foundation
import StoreKit

/// Domain state for the Paywall feature business logic.
///
/// This represents the current state of the Paywall domain,
/// containing all data and status information needed by the business logic.
struct PaywallDomainState: Equatable {
    /// Available products for purchase.
    var products: [Product]

    /// Currently selected product.
    var selectedProduct: Product?

    /// Whether the user has an active subscription.
    var isPremium: Bool

    /// Loading state for products.
    var isLoadingProducts: Bool

    /// Loading state for purchase.
    var isPurchasing: Bool

    /// Loading state for restore.
    var isRestoring: Bool

    /// Current error message.
    var error: String?

    /// Whether purchase was successful.
    var purchaseSuccessful: Bool

    /// Whether restore was successful.
    var restoreSuccessful: Bool

    /// Whether to dismiss the paywall.
    var shouldDismiss: Bool

    /// Default initial state.
    static let initial = PaywallDomainState(
        products: [],
        selectedProduct: nil,
        isPremium: false,
        isLoadingProducts: false,
        isPurchasing: false,
        isRestoring: false,
        error: nil,
        purchaseSuccessful: false,
        restoreSuccessful: false,
        shouldDismiss: false
    )

    static func == (lhs: PaywallDomainState, rhs: PaywallDomainState) -> Bool {
        let productsEqual = lhs.products.map(\.id) == rhs.products.map(\.id)
        let selectedEqual = lhs.selectedProduct?.id == rhs.selectedProduct?.id

        return productsEqual &&
            selectedEqual &&
            lhs.isPremium == rhs.isPremium &&
            lhs.isLoadingProducts == rhs.isLoadingProducts &&
            lhs.isPurchasing == rhs.isPurchasing &&
            lhs.isRestoring == rhs.isRestoring &&
            lhs.error == rhs.error &&
            lhs.purchaseSuccessful == rhs.purchaseSuccessful &&
            lhs.restoreSuccessful == rhs.restoreSuccessful &&
            lhs.shouldDismiss == rhs.shouldDismiss
    }
}

// MARK: - PaywallDomainState Helper Extension

extension PaywallDomainState {
    /// Create a copy of the current state with modified properties.
    func copy(
        products: [Product]? = nil,
        selectedProduct: Product?? = nil,
        isPremium: Bool? = nil,
        isLoadingProducts: Bool? = nil,
        isPurchasing: Bool? = nil,
        isRestoring: Bool? = nil,
        error: String?? = nil,
        purchaseSuccessful: Bool? = nil,
        restoreSuccessful: Bool? = nil,
        shouldDismiss: Bool? = nil
    ) -> PaywallDomainState {
        PaywallDomainState(
            products: products ?? self.products,
            selectedProduct: selectedProduct ?? self.selectedProduct,
            isPremium: isPremium ?? self.isPremium,
            isLoadingProducts: isLoadingProducts ?? self.isLoadingProducts,
            isPurchasing: isPurchasing ?? self.isPurchasing,
            isRestoring: isRestoring ?? self.isRestoring,
            error: error ?? self.error,
            purchaseSuccessful: purchaseSuccessful ?? self.purchaseSuccessful,
            restoreSuccessful: restoreSuccessful ?? self.restoreSuccessful,
            shouldDismiss: shouldDismiss ?? self.shouldDismiss
        )
    }
}
