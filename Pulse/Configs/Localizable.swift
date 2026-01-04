//
//  Localizable.swift
//  Pulse
//
//  Created by bruno on localization.
//

import Foundation

/// Localizable wrapper providing easy access to localized strings.
///
/// This struct provides a centralized way to access localized strings throughout the app.
/// It uses NSLocalizedString internally and provides type-safe access to all localized content.
///
/// Example usage:
/// ```swift
/// Text(Localizable.paywall.title)
/// ```
struct Localizable {
    // MARK: - Private Initializer

    /// Private initializer to prevent instantiation
    private init() {}

    // MARK: - Paywall

    /// Paywall related localized strings
    struct Paywall {
        /// Private initializer to prevent instantiation
        private init() {}

        /// "Loading..." loading state message
        static let loading = String(localized: "paywall.loading")

        /// "Unlock Premium" title
        static let title = String(localized: "paywall.title")

        /// Subtitle describing premium benefits
        static let subtitle = String(localized: "paywall.subtitle")

        /// First feature title
        static let feature1Title = String(localized: "paywall.feature1.title")

        /// First feature description
        static let feature1Description = String(localized: "paywall.feature1.description")

        /// Second feature title
        static let feature2Title = String(localized: "paywall.feature2.title")

        /// Second feature description
        static let feature2Description = String(localized: "paywall.feature2.description")

        /// Third feature title
        static let feature3Title = String(localized: "paywall.feature3.title")

        /// Third feature description
        static let feature3Description = String(localized: "paywall.feature3.description")

        /// "Error" title for error state
        static let errorTitle = String(localized: "paywall.error.title")

        /// "Retry" button text
        static let retry = String(localized: "paywall.retry")

        /// "Restore Purchases" button text
        static let restorePurchases = String(localized: "paywall.restore_purchases")

        /// "Go Premium" settings entry point title
        static let goPremium = String(localized: "paywall.go_premium")

        /// "Unlock all features" settings entry point description
        static let unlockFeatures = String(localized: "paywall.unlock_features")

        /// "Premium Active" status for subscribed users
        static let premiumActive = String(localized: "paywall.premium_active")

        /// "You have full access" description for subscribed users
        static let fullAccess = String(localized: "paywall.full_access")
    }

    // MARK: - Convenience Access

    /// Convenience access to paywall strings
    static let paywall = Paywall.self
}
