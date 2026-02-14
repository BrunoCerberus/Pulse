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
            return true
        }
    }

    var errorDescription: String? {
        switch self {
        case .offlineNoCache:
            return String(
                localized: "error.offline.no_cache",
                defaultValue: "You're offline and no cached content is available."
            )
        }
    }
}

extension Error {
    /// Whether this error represents an offline condition.
    var isOfflineError: Bool {
        (self as? PulseError)?.isOfflineError ?? false
    }
}
