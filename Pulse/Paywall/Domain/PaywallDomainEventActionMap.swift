//
//  PaywallDomainEventActionMap.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Foundation

/// Maps PaywallViewEvent to PaywallDomainAction.
///
/// This enum provides a centralized mapping between view events and domain actions,
/// keeping the view layer separated from business logic.
enum PaywallDomainEventActionMap {
    /// Map a view event to its corresponding domain action.
    ///
    /// - Parameter event: The view event to map.
    /// - Returns: The corresponding domain action.
    static func map(_ event: PaywallViewEvent) -> PaywallDomainAction {
        switch event {
        case .viewDidAppear:
            .loadProducts

        case let .productSelected(product):
            .selectProduct(product)

        case let .purchaseRequested(product):
            .purchase(product)

        case .restorePurchasesTapped:
            .restorePurchases

        case .dismissTapped:
            .dismiss
        }
    }
}
