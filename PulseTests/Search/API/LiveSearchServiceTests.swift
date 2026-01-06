import Combine
import Foundation
@testable import Pulse
import Testing

@Suite("LiveSearchService Tests", .serialized)
@MainActor
struct LiveSearchServiceTests {
    private let recentSearchesKey = "pulse.recentSearches"
    let sut = LiveSearchService()

    // Helper to set up recent searches for testing
    private func setRecentSearches(_ searches: [String]) {
        UserDefaults.standard.set(searches, forKey: recentSearchesKey)
        UserDefaults.standard.synchronize()
    }

    private func clearRecentSearches() {
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
        UserDefaults.standard.synchronize()
    }

    // MARK: - getSuggestions Tests

    @Test("getSuggestions returns empty when no recent searches")
    func getSuggestionsEmptyWhenNoRecentSearches() async throws {
        clearRecentSearches()
        defer { clearRecentSearches() }

        var result: [String] = []
        var cancellables = Set<AnyCancellable>()

        sut.getSuggestions(for: "test")
            .sink { suggestions in
                result = suggestions
            }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(result.isEmpty)
    }

    @Test("getSuggestions filters by query case-insensitively")
    func getSuggestionsFiltersCaseInsensitive() async throws {
        clearRecentSearches()
        setRecentSearches(["Swift", "SwiftUI", "Objective-C", "iOS"])
        defer { clearRecentSearches() }

        var result: [String] = []
        var cancellables = Set<AnyCancellable>()

        sut.getSuggestions(for: "swift")
            .sink { suggestions in
                result = suggestions
            }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(result.count == 2)
        #expect(result.contains("Swift"))
        #expect(result.contains("SwiftUI"))
    }

    @Test("getSuggestions matches partial query")
    func getSuggestionsMatchesPartialQuery() async throws {
        clearRecentSearches()
        setRecentSearches(["Technology", "Tech News", "Sports"])
        defer { clearRecentSearches() }

        var result: [String] = []
        var cancellables = Set<AnyCancellable>()

        sut.getSuggestions(for: "tech")
            .sink { suggestions in
                result = suggestions
            }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(result.count == 2)
        #expect(result.contains("Technology"))
        #expect(result.contains("Tech News"))
    }

    @Test("getSuggestions returns all matches")
    func getSuggestionsReturnsAllMatches() async throws {
        clearRecentSearches()
        setRecentSearches(["Apple", "Banana", "Apricot", "Avocado", "Cherry"])
        defer { clearRecentSearches() }

        var result: [String] = []
        var cancellables = Set<AnyCancellable>()

        sut.getSuggestions(for: "a")
            .sink { suggestions in
                result = suggestions
            }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(result.count == 4)
        #expect(result.contains("Apple"))
        #expect(result.contains("Banana"))
        #expect(result.contains("Apricot"))
        #expect(result.contains("Avocado"))
    }

    @Test("getSuggestions with common substring returns multiple matches")
    func getSuggestionsCommonSubstringReturnsMultiple() async throws {
        clearRecentSearches()
        setRecentSearches(["SwiftUI", "Swift"])
        defer { clearRecentSearches() }

        var result: [String] = []
        var cancellables = Set<AnyCancellable>()

        // Query "Swift" should match both "Swift" and "SwiftUI"
        sut.getSuggestions(for: "Swift")
            .sink { suggestions in
                result = suggestions
            }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(result.count == 2)
        #expect(result.contains("Swift"))
        #expect(result.contains("SwiftUI"))
    }

    @Test("getSuggestions preserves order from UserDefaults")
    func getSuggestionsPreservesOrder() async throws {
        clearRecentSearches()
        setRecentSearches(["First App", "Second App", "Third App"])
        defer { clearRecentSearches() }

        var result: [String] = []
        var cancellables = Set<AnyCancellable>()

        // Query "App" matches all and preserves order
        sut.getSuggestions(for: "App")
            .sink { suggestions in
                result = suggestions
            }
            .store(in: &cancellables)

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(result == ["First App", "Second App", "Third App"])
    }

    @Test("getSuggestions returns immediately via Just publisher")
    func getSuggestionsReturnsImmediately() async throws {
        clearRecentSearches()
        setRecentSearches(["Test"])
        defer { clearRecentSearches() }

        var completed = false
        var cancellables = Set<AnyCancellable>()

        sut.getSuggestions(for: "Test")
            .sink { _ in
                completed = true
            }
            .store(in: &cancellables)

        // Should complete synchronously since Just is synchronous
        #expect(completed)
    }
}
