import Foundation
import UIKit

/// Defines the static Home Screen Quick Actions the app exposes.
enum QuickActionType: String, CaseIterable {
    case search
    case dailyDigest
    case bookmarks
    case breakingNews

    /// Shortcut identifier used by `UIApplicationShortcutItem`.
    var shortcutType: String {
        "com.bruno.Pulse-News.quickaction.\(rawValue)"
    }

    /// Localized title shown under the app icon.
    var localizedTitle: String {
        switch self {
        case .search: AppLocalization.localized("quick_action.search.title")
        case .dailyDigest: AppLocalization.localized("quick_action.daily_digest.title")
        case .bookmarks: AppLocalization.localized("quick_action.bookmarks.title")
        case .breakingNews: AppLocalization.localized("quick_action.breaking_news.title")
        }
    }

    /// SF Symbol for the icon.
    var systemImageName: String {
        switch self {
        case .search: "magnifyingglass"
        case .dailyDigest: "text.document"
        case .bookmarks: "bookmark.fill"
        case .breakingNews: "bolt.fill"
        }
    }

    /// Builds the corresponding `UIApplicationShortcutItem`.
    func shortcutItem() -> UIApplicationShortcutItem {
        UIApplicationShortcutItem(
            type: shortcutType,
            localizedTitle: localizedTitle,
            localizedSubtitle: nil,
            icon: UIApplicationShortcutIcon(systemImageName: systemImageName)
        )
    }

    /// Parses a shortcut item back into a `QuickActionType`.
    init?(shortcutItem: UIApplicationShortcutItem) {
        guard let match = Self.allCases.first(where: { $0.shortcutType == shortcutItem.type }) else {
            return nil
        }
        self = match
    }
}
