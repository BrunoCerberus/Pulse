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
