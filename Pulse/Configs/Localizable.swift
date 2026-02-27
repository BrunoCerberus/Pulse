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
        static var loading: String {
            AppLocalization.localized("paywall.loading")
        }

        /// "Unlock Premium" title
        static var title: String {
            AppLocalization.localized("paywall.title")
        }

        /// Subtitle describing premium benefits
        static var subtitle: String {
            AppLocalization.localized("paywall.subtitle")
        }

        /// First feature title
        static var feature1Title: String {
            AppLocalization.localized("paywall.feature1.title")
        }

        /// First feature description
        static var feature1Description: String {
            AppLocalization.localized("paywall.feature1.description")
        }

        /// Second feature title
        static var feature2Title: String {
            AppLocalization.localized("paywall.feature2.title")
        }

        /// Second feature description
        static var feature2Description: String {
            AppLocalization.localized("paywall.feature2.description")
        }

        /// Third feature title
        static var feature3Title: String {
            AppLocalization.localized("paywall.feature3.title")
        }

        /// Third feature description
        static var feature3Description: String {
            AppLocalization.localized("paywall.feature3.description")
        }

        /// "Error" title for error state
        static var errorTitle: String {
            AppLocalization.localized("paywall.error.title")
        }

        /// "Retry" button text
        static var retry: String {
            AppLocalization.localized("paywall.retry")
        }

        /// "Restore Purchases" button text
        static var restorePurchases: String {
            AppLocalization.localized("paywall.restore_purchases")
        }

        /// "Go Premium" settings entry point title
        static var goPremium: String {
            AppLocalization.localized("paywall.go_premium")
        }

        /// "Unlock all features" settings entry point description
        static var unlockFeatures: String {
            AppLocalization.localized("paywall.unlock_features")
        }

        /// "Premium Active" status for subscribed users
        static var premiumActive: String {
            AppLocalization.localized("paywall.premium_active")
        }

        /// "You have full access" description for subscribed users
        static var fullAccess: String {
            AppLocalization.localized("paywall.full_access")
        }
    }

    // MARK: - Convenience Access

    /// Convenience access to paywall strings
    static let paywall = Paywall.self
}
