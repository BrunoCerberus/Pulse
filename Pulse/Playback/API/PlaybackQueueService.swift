import Combine
import Foundation

/// What kind of playback session the queue is running.
enum PlaybackMode: Equatable {
    /// A single article started from the article detail "Listen" button.
    case singleArticle
    /// The Premium audio briefing: digest narration followed by For You articles.
    case briefing
}

/// One narratable unit in the playback queue.
///
/// Items are immutable snapshots: the speech text, title, and language are
/// captured when the queue is built, so a digest regeneration or a runtime
/// language switch never affects a queue that is already playing.
struct PlaybackItem: Identifiable, Equatable {
    enum Kind: Equatable {
        case digest
        case article(Article)
    }

    let id: String
    let kind: Kind
    let title: String
    let sourceName: String
    let speechText: String
    let language: String
}

extension PlaybackItem {
    /// Builds the queue item for an article, snapshotting its narration text
    /// and the given content language.
    static func article(_ article: Article, language: String) -> PlaybackItem {
        PlaybackItem(
            id: article.id,
            kind: .article(article),
            title: article.title,
            sourceName: article.source.name,
            speechText: SpeechTextBuilder.speechText(for: article),
            language: language,
        )
    }

    /// Builds a briefing-queue article item, prefixed with a spoken "Next up,
    /// from <source>" transition so consecutive items don't hard-cut into
    /// each other. Distinct from `article(_:language:)` so the single-article
    /// "Listen" entry point (Article Detail) never picks up briefing framing.
    static func briefingArticle(_ article: Article, language: String) -> PlaybackItem {
        PlaybackItem(
            id: article.id,
            kind: .article(article),
            title: article.title,
            sourceName: article.source.name,
            speechText: SpeechTextBuilder.briefingSpeechText(for: article),
            language: language,
        )
    }

    /// Builds the narration item for the AI daily digest.
    static func digest(_ digest: DailyDigest, language: String) -> PlaybackItem {
        PlaybackItem(
            id: "digest-\(digest.id)",
            kind: .digest,
            title: AppLocalization.localized("briefing.digest_item_title"),
            sourceName: "Pulse",
            speechText: SpeechTextBuilder.speechText(forDigestSummary: digest.summary),
            language: language,
        )
    }
}

/// Snapshot of the playback queue published to consumers.
struct PlaybackQueueState: Equatable {
    var items: [PlaybackItem]
    /// Index of the item currently loaded in the synthesizer.
    /// `nil` means the queue is inactive and no player UI should be shown.
    var currentIndex: Int?
    var playbackState: TTSPlaybackState
    /// Progress (0...1) through the current item.
    var itemProgress: Double
    var speedPreset: TTSSpeedPreset
    var mode: PlaybackMode

    var currentItem: PlaybackItem? {
        guard let currentIndex, items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    var hasNext: Bool {
        guard let currentIndex else { return false }
        return currentIndex + 1 < items.count
    }

    var hasPrevious: Bool {
        guard let currentIndex else { return false }
        return currentIndex > 0
    }

    /// Human-readable queue position (e.g. `"2/11"`); `nil` for single-article
    /// playback where a position would be noise.
    var queuePositionLabel: String? {
        guard mode == .briefing, let currentIndex, !items.isEmpty else { return nil }
        return "\(currentIndex + 1)/\(items.count)"
    }

    /// Progress (0...1) across the whole queue, weighting every item equally.
    var overallProgress: Double {
        guard let currentIndex, !items.isEmpty else { return 0 }
        return (Double(currentIndex) + itemProgress) / Double(items.count)
    }

    static let idle = PlaybackQueueState(
        items: [],
        currentIndex: nil,
        playbackState: .idle,
        itemProgress: 0.0,
        speedPreset: .normal,
        mode: .singleArticle,
    )
}

/// Global playback queue — the single owner of `TextToSpeechService`.
///
/// All speech in the app flows through this service so there is exactly one
/// playback session, one Now Playing entry, one Live Activity, and one mini
/// player, regardless of which screen started playback. Playback deliberately
/// survives navigation; `stop()` is the only teardown path.
///
/// `@MainActor` because the service drives ActivityKit and MediaPlayer state
/// that must be touched from the main actor; all consumers (interactors,
/// view models) are main-actor types.
@MainActor
protocol PlaybackQueueService: AnyObject {
    var statePublisher: AnyPublisher<PlaybackQueueState, Never> { get }
    var currentState: PlaybackQueueState { get }

    /// Replaces whatever is playing with the given queue and starts speaking
    /// the first item. Always replace semantics — never appends.
    func play(items: [PlaybackItem], mode: PlaybackMode)

    /// Pauses if playing, resumes if paused. No-op when the queue is inactive.
    func togglePlayPause()

    /// Advances to the next item; stops at the end of the queue.
    func next()

    /// Restarts the previous item; no-op on the first item.
    func previous()

    /// Jumps to the item with the given ID, if present in the queue.
    func skip(to itemID: String)

    /// Cycles the speed preset; restarts the current item at the new rate.
    func cycleSpeed()

    /// Stops playback and clears the queue. Deactivates the audio session.
    func stop()
}
