import Foundation

/// Actions that can be dispatched to `ForYouDomainInteractor`.
enum ForYouDomainAction: Equatable {
    /// Score `pool` against the current profile and refresh the visible
    /// carousel. Dispatched whenever the host's article pool changes
    /// (initial load, refresh, category-filter cleared).
    case scoreFromPool(pool: [Article])

    /// Re-runs scoring against the previously-supplied pool — used when
    /// the profile changes (`.interestProfileDidChange` /
    /// `.cloudSyncDidComplete`) and we want fresh ranking without
    /// re-fetching from the host.
    case rescore

    /// Push a new feature-flag value (driven by Remote Config).
    case setFeatureEnabled(Bool)
}
