//
//  PaywallViewStateReducer.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Foundation

/// Protocol for reducing domain state to view state.
///
/// This protocol defines the contract for converting domain state
/// to view state, following the Clean Architecture pattern.
protocol PaywallViewStateReducing {
    /// Reduce domain state to view state.
    ///
    /// - Parameter domainState: The current domain state.
    /// - Returns: The corresponding view state.
    func reduce(_ domainState: PaywallDomainState) -> PaywallViewState
}

/// Concrete implementation of PaywallViewStateReducing.
///
/// This reducer converts domain state to view state for the Paywall feature.
struct PaywallViewStateReducer: PaywallViewStateReducing {
    /// Reduce domain state to view state.
    ///
    /// This method converts the domain state to the appropriate view state
    /// based on loading status, error conditions, and data availability.
    ///
    /// - Parameter domainState: The current domain state.
    /// - Returns: The corresponding view state.
    func reduce(_ domainState: PaywallDomainState) -> PaywallViewState {
        // Check for error state
        if let error = domainState.error {
            return .error(error)
        }

        // Check for loading state
        if domainState.isLoadingProducts {
            return .loading
        }

        // Create success state with data
        let dataViewState = PaywallDataViewState(
            products: domainState.products,
            selectedProduct: domainState.selectedProduct,
            isPremium: domainState.isPremium,
            isPurchasing: domainState.isPurchasing,
            isRestoring: domainState.isRestoring,
            purchaseSuccessful: domainState.purchaseSuccessful,
            restoreSuccessful: domainState.restoreSuccessful,
            shouldDismiss: domainState.shouldDismiss
        )

        return .success(dataViewState)
    }
}
