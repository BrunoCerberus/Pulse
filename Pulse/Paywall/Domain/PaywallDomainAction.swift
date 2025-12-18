//
//  PaywallDomainAction.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Foundation
import StoreKit

/// Domain actions for the Paywall feature business logic.
///
/// These actions represent the business operations that can be performed
/// within the Paywall domain, independent of UI concerns.
enum PaywallDomainAction: Equatable {
    case loadProducts
    case selectProduct(Product)
    case purchase(Product)
    case restorePurchases
    case dismiss
    case checkSubscriptionStatus

    static func == (lhs: PaywallDomainAction, rhs: PaywallDomainAction) -> Bool {
        switch (lhs, rhs) {
        case (.loadProducts, .loadProducts),
             (.restorePurchases, .restorePurchases),
             (.dismiss, .dismiss),
             (.checkSubscriptionStatus, .checkSubscriptionStatus):
            true
        case let (.selectProduct(lhsProduct), .selectProduct(rhsProduct)),
             let (.purchase(lhsProduct), .purchase(rhsProduct)):
            lhsProduct.id == rhsProduct.id
        default:
            false
        }
    }
}
