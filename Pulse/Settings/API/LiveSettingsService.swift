import Combine
import Foundation

final class LiveSettingsService: SettingsService {
    private let storageService: StorageService

    init(storageService: StorageService) {
        self.storageService = storageService
    }

    func fetchPreferences() -> AnyPublisher<UserPreferences, Error> {
        Future { [storageService] promise in
            Task.detached {
                do {
                    let preferences = try await storageService.fetchUserPreferences() ?? .default
                    promise(.success(preferences))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func savePreferences(_ preferences: UserPreferences) -> AnyPublisher<Void, Error> {
        Future { [storageService] promise in
            Task.detached {
                do {
                    try await storageService.saveUserPreferences(preferences)
                    // Mirror notification preference to UserDefaults for PulseAppDelegate
                    // to check in willPresent without needing SwiftData access
                    UserDefaults.standard.set(preferences.notificationsEnabled, forKey: "pulse.notificationsEnabled")
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
