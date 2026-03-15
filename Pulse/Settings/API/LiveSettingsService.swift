import Combine
import Foundation

final class LiveSettingsService: SettingsService, @unchecked Sendable {
    private let storageService: StorageService

    init(storageService: StorageService) {
        self.storageService = storageService
    }

    func fetchPreferences() -> AnyPublisher<UserPreferences, Error> {
        let storageService = UncheckedSendableBox(value: storageService)
        return Future { promise in
            let promise = UncheckedSendableBox(value: promise)
            Task.detached {
                do {
                    let preferences = try await storageService.value.fetchUserPreferences() ?? .default
                    promise.value(.success(preferences))
                } catch {
                    promise.value(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func savePreferences(_ preferences: UserPreferences) -> AnyPublisher<Void, Error> {
        let storageService = UncheckedSendableBox(value: storageService)
        return Future { promise in
            let promise = UncheckedSendableBox(value: promise)
            Task.detached {
                do {
                    try await storageService.value.saveUserPreferences(preferences)
                    // Mirror notification preference to UserDefaults for PulseAppDelegate
                    // to check in willPresent without needing SwiftData access
                    UserDefaults.standard.set(preferences.notificationsEnabled, forKey: "pulse.notificationsEnabled")
                    promise.value(.success(()))
                } catch {
                    promise.value(.failure(error))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
