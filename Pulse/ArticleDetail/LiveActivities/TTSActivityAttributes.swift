import ActivityKit
import Foundation

/// Attributes describing a Text-to-Speech playback Live Activity.
///
/// Static (immutable) fields describe the article being read aloud, while
/// `ContentState` carries the live-updating playback information that the
/// system displays on the Lock Screen and in the Dynamic Island.
///
/// This file is compiled into BOTH the main Pulse app target and the
/// PulseWidgetExtension target so the controller and the widget UI can
/// share the same type-safe activity definition.
struct TTSActivityAttributes: ActivityAttributes {
    /// Mutable, frequently-updated playback state for the activity.
    struct ContentState: Codable, Hashable {
        /// Whether speech is currently playing (vs. paused).
        var isPlaying: Bool

        /// Speech progress in the range `0.0...1.0`.
        var progress: Double

        /// Display label for the current speed preset (e.g. "1x", "1.25x", "1.5x", "2x").
        var speedLabel: String
    }

    /// Title of the article being read aloud.
    let articleTitle: String

    /// Display name of the article's source (e.g. "BBC News").
    let sourceName: String
}
