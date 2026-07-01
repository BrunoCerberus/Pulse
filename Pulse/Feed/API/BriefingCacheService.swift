import Foundation

/// Persists today's opportunistically pre-generated Morning Briefing so it
/// survives the app being killed and relaunched by a notification tap —
/// unlike `FeedService`'s in-memory-only digest cache, which doesn't.
///
/// Backed by `UserDefaults`, not SwiftData: this is a single, disposable
/// entry overwritten daily and meaningless to sync across the user's other
/// devices (each device regenerates its own text on-device).
protocol BriefingCacheService {
    /// Persists a freshly generated briefing, replacing any prior entry.
    func store(_ briefing: PregeneratedBriefing)

    /// Returns the cached briefing if it was generated earlier today,
    /// `nil` if there is none or it's stale (from a previous day).
    func fetchIfFreshToday() -> PregeneratedBriefing?
}

final class LiveBriefingCacheService: BriefingCacheService {
    private static let storageKey = "pulse.pregeneratedBriefing"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func store(_ briefing: PregeneratedBriefing) {
        guard let data = try? JSONEncoder().encode(briefing) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    func fetchIfFreshToday() -> PregeneratedBriefing? {
        guard let data = defaults.data(forKey: Self.storageKey),
              let briefing = try? JSONDecoder().decode(PregeneratedBriefing.self, from: data),
              Calendar.current.isDateInToday(briefing.generatedAt)
        else {
            return nil
        }
        return briefing
    }
}
