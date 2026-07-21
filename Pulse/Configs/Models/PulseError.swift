import Foundation

/// Typed error for distinguishing offline errors from server errors.
///
/// Used by the caching layer and interactors to provide context-aware
/// error messages and UI states when the device is offline.
enum PulseError: Error, LocalizedError {
    /// The device is offline and no cached data is available.
    case offlineNoCache

    /// Whether this error represents an offline condition.
    var isOfflineError: Bool {
        switch self {
        case .offlineNoCache:
            true
        }
    }

    var errorDescription: String? {
        switch self {
        case .offlineNoCache:
            // `errorDescription` is `nonisolated`; use the `nonisolated static`
            // shorthand rather than `AppLocalization.shared` (a @MainActor static)
            // so this compiles under Swift 6.2 strict concurrency.
            AppLocalization.localized("error.offline.no_cache")
        }
    }
}

extension Error {
    /// Whether this error represents an offline condition.
    var isOfflineError: Bool {
        (self as? PulseError)?.isOfflineError ?? false
    }
}
