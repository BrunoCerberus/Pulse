import Combine
import EntropyCore
import Foundation
@testable import Pulse
import Testing

@Suite("LiveSettingsService Tests")
struct LiveSettingsServiceTests {
    let mockStorageService: MockStorageService

    init() {
        mockStorageService = MockStorageService()
    }

    private func createSUT() -> LiveSettingsService {
        LiveSettingsService(storageService: mockStorageService)
    }

    // MARK: - Fetch Preferences Tests

    @Test("fetchPreferences returns stored preferences")
    func fetchPreferencesSuccess() async throws {
        let testPreferences = UserPreferences(
            followedTopics: [.technology, .science],
            followedSources: [],
            mutedSources: ["Source1"],
            mutedKeywords: ["keyword1"],
            preferredLanguage: "en",
            notificationsEnabled: true,
            breakingNewsNotifications: false
        )
        mockStorageService.userPreferences = testPreferences
        let sut = createSUT()

        var cancellables = Set<AnyCancellable>()
        var receivedPreferences: UserPreferences?
        var receivedError: Error?

        await withCheckedContinuation { continuation in
            sut.fetchPreferences()
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            receivedError = error
                        }
                        continuation.resume(returning: ())
                    },
                    receiveValue: { preferences in
                        receivedPreferences = preferences
                    }
                )
                .store(in: &cancellables)
        }

        #expect(receivedError == nil)
        #expect(receivedPreferences?.followedTopics.contains(.technology) == true)
        #expect(receivedPreferences?.followedTopics.contains(.science) == true)
        #expect(receivedPreferences?.notificationsEnabled == true)
        #expect(receivedPreferences?.breakingNewsNotifications == false)
    }

    @Test("fetchPreferences returns default when no preferences stored")
    func fetchPreferencesDefault() async throws {
        mockStorageService.userPreferences = nil
        let sut = createSUT()

        var cancellables = Set<AnyCancellable>()
        var receivedPreferences: UserPreferences?

        await withCheckedContinuation { continuation in
            sut.fetchPreferences()
                .sink(
                    receiveCompletion: { _ in
                        continuation.resume(returning: ())
                    },
                    receiveValue: { preferences in
                        receivedPreferences = preferences
                    }
                )
                .store(in: &cancellables)
        }

        // Should return default preferences
        #expect(receivedPreferences != nil)
        #expect(receivedPreferences?.followedTopics == UserPreferences.default.followedTopics)
    }

    @Test("fetchPreferences propagates storage errors")
    func fetchPreferencesError() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        mockStorageService.fetchPreferencesError = testError
        let sut = createSUT()

        var cancellables = Set<AnyCancellable>()
        var receivedError: Error?

        await withCheckedContinuation { continuation in
            sut.fetchPreferences()
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            receivedError = error
                        }
                        continuation.resume(returning: ())
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }

        #expect(receivedError != nil)
    }

    // MARK: - Save Preferences Tests

    @Test("savePreferences stores preferences successfully")
    func savePreferencesSuccess() async throws {
        let sut = createSUT()
        let preferencesToSave = UserPreferences(
            followedTopics: [.business],
            followedSources: [],
            mutedSources: [],
            mutedKeywords: [],
            preferredLanguage: "en",
            notificationsEnabled: false,
            breakingNewsNotifications: true
        )

        var cancellables = Set<AnyCancellable>()
        var completedSuccessfully = false
        var receivedError: Error?

        await withCheckedContinuation { continuation in
            sut.savePreferences(preferencesToSave)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            completedSuccessfully = true
                        case let .failure(error):
                            receivedError = error
                        }
                        continuation.resume(returning: ())
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }

        #expect(completedSuccessfully)
        #expect(receivedError == nil)

        // Verify the preferences were saved
        let savedPreferences = try await mockStorageService.fetchUserPreferences()
        #expect(savedPreferences?.followedTopics.contains(.business) == true)
        #expect(savedPreferences?.notificationsEnabled == false)
        #expect(savedPreferences?.breakingNewsNotifications == true)
    }

    @Test("savePreferences propagates storage errors")
    func savePreferencesError() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        mockStorageService.savePreferencesError = testError
        let sut = createSUT()

        var cancellables = Set<AnyCancellable>()
        var receivedError: Error?

        await withCheckedContinuation { continuation in
            sut.savePreferences(.default)
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            receivedError = error
                        }
                        continuation.resume(returning: ())
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }

        #expect(receivedError != nil)
    }

    // MARK: - Clear Reading History Tests

    @Test("clearReadingHistory clears history successfully")
    func clearReadingHistorySuccess() async throws {
        // Add some reading history first
        mockStorageService.readingHistory = Article.mockArticles
        let sut = createSUT()

        var cancellables = Set<AnyCancellable>()
        var completedSuccessfully = false
        var receivedError: Error?

        await withCheckedContinuation { continuation in
            sut.clearReadingHistory()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            completedSuccessfully = true
                        case let .failure(error):
                            receivedError = error
                        }
                        continuation.resume(returning: ())
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }

        #expect(completedSuccessfully)
        #expect(receivedError == nil)

        // Verify the history was cleared
        let remainingHistory = try await mockStorageService.fetchReadingHistory()
        #expect(remainingHistory.isEmpty)
    }

    @Test("clearReadingHistory propagates storage errors")
    func clearReadingHistoryError() async throws {
        let testError = NSError(domain: "test", code: 1, userInfo: nil)
        mockStorageService.clearHistoryError = testError
        let sut = createSUT()

        var cancellables = Set<AnyCancellable>()
        var receivedError: Error?

        await withCheckedContinuation { continuation in
            sut.clearReadingHistory()
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            receivedError = error
                        }
                        continuation.resume(returning: ())
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }

        #expect(receivedError != nil)
    }
}
