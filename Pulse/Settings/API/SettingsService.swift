import Combine
import Foundation

/// Protocol defining the interface for managing user settings and preferences.
///
/// This protocol provides operations for persisting and retrieving user preferences
/// such as followed topics, notification settings, theme, and muted content.
///
/// The default implementation (`LiveSettingsService`) uses `StorageService`
/// (SwiftData) for persistence.
protocol SettingsService {
    /// Fetches the current user preferences.
    /// - Returns: Publisher emitting the user's preferences or an error.
    func fetchPreferences() -> AnyPublisher<UserPreferences, Error>

    /// Saves updated user preferences.
    /// - Parameter preferences: The preferences to save.
    /// - Returns: Publisher that completes on success or emits an error.
    func savePreferences(_ preferences: UserPreferences) -> AnyPublisher<Void, Error>
}

extension SettingsService {
    /// Bridges `fetchPreferences()` to a single async read, for callers that
    /// just need a one-shot snapshot rather than a live subscription.
    /// Resolves to `nil` on error or if the publisher completes without ever
    /// emitting a value (e.g. an empty store) — either way the continuation
    /// must resume exactly once or the awaiting `Task` hangs forever.
    func fetchPreferencesOnce() async -> UserPreferences? {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            var didResume = false
            cancellable = fetchPreferences()
                .first()
                .sink(
                    receiveCompletion: { _ in
                        if !didResume {
                            didResume = true
                            continuation.resume(returning: nil)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { preferences in
                        didResume = true
                        continuation.resume(returning: preferences)
                    }
                )
        }
    }
}
