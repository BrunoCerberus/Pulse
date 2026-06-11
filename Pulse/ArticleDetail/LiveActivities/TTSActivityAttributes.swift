import ActivityKit
import Foundation

/// Attributes describing a Text-to-Speech playback Live Activity.
///
/// A single activity spans an entire playback queue (briefing or single
/// article), so everything that can change mid-session — including the title
/// and source of the item currently being narrated — lives in `ContentState`.
/// The attributes themselves carry no fixed payload.
///
/// This file is compiled into BOTH the main Pulse app target and the
/// PulseWidgetExtension target so the controller and the widget UI can
/// share the same type-safe activity definition.
struct TTSActivityAttributes: ActivityAttributes {
    /// Mutable, frequently-updated playback state for the activity.
    struct ContentState: Codable, Hashable {
        /// Whether speech is currently playing (vs. paused).
        var isPlaying: Bool

        /// Speech progress for the current item in the range `0.0...1.0`.
        var progress: Double

        /// Display label for the current speed preset (e.g. "1x", "1.25x", "1.5x", "2x").
        var speedLabel: String

        /// Title of the item currently being narrated.
        var currentTitle: String

        /// Display name of the current item's source (e.g. "BBC News").
        var currentSource: String

        /// Queue position label (e.g. "2/11"); `nil` for single-article playback.
        var queuePosition: String?
    }
}
