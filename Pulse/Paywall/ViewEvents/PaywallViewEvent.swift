//
//  PaywallViewEvent.swift
//  Pulse
//
//  Created by bruno on paywall functionality.
//

import Foundation
import StoreKit

/// User/intention events originating from the Paywall view.
enum PaywallViewEvent: Equatable {
    case viewDidAppear
    case productSelected(Product)
    case purchaseRequested(Product)
    case restorePurchasesTapped
    case dismissTapped

    static func == (lhs: PaywallViewEvent, rhs: PaywallViewEvent) -> Bool {
        switch (lhs, rhs) {
        case (.viewDidAppear, .viewDidAppear),
             (.restorePurchasesTapped, .restorePurchasesTapped),
             (.dismissTapped, .dismissTapped):
            true
        case let (.productSelected(lhsProduct), .productSelected(rhsProduct)),
             let (.purchaseRequested(lhsProduct), .purchaseRequested(rhsProduct)):
            lhsProduct.id == rhsProduct.id
        default:
            false
        }
    }
}
