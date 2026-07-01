import Foundation

/// A digest + ForYou queue generated ahead of time (opportunistically, while
/// the app was foregrounded earlier in the day) so tapping the scheduled
/// Morning Briefing notification can start playback instantly instead of
/// waiting on a fresh LLM generation.
struct PregeneratedBriefing: Codable {
    let digest: DailyDigest
    let queueArticles: [Article]
    let generatedAt: Date
}
