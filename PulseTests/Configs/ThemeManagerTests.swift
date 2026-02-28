import Combine
import Foundation
@testable import Pulse
import SwiftUI
import Testing

@Suite("ThemeManager Tests", .serialized)
@MainActor
struct ThemeManagerTests {
    // Note: ThemeManager uses a shared singleton, so tests must be serialized
    // and we restore state after each test

    // MARK: - Singleton Tests

    @Test("Shared instance is accessible")
    func sharedInstanceAccessible() {
        // Accessing shared singleton succeeds without crash
        _ = ThemeManager.shared
    }

    // MARK: - ColorScheme Tests

    @Test("ColorScheme is nil when useSystemTheme is true")
    func colorSchemeNilWhenUseSystemTheme() {
        let manager = ThemeManager.shared
        let originalUseSystemTheme = manager.useSystemTheme
        defer { manager.useSystemTheme = originalUseSystemTheme }

        manager.useSystemTheme = true

        #expect(manager.colorScheme == nil)
    }

    @Test("ColorScheme is dark when useSystemTheme is false and isDarkMode is true")
    func colorSchemeDarkWhenDarkModeEnabled() {
        let manager = ThemeManager.shared
        let originalUseSystemTheme = manager.useSystemTheme
        let originalIsDarkMode = manager.isDarkMode
        defer {
            manager.useSystemTheme = originalUseSystemTheme
            manager.isDarkMode = originalIsDarkMode
        }

        manager.useSystemTheme = false
        manager.isDarkMode = true

        #expect(manager.colorScheme == .dark)
    }

    @Test("ColorScheme is light when useSystemTheme is false and isDarkMode is false")
    func colorSchemeLightWhenDarkModeDisabled() {
        let manager = ThemeManager.shared
        let originalUseSystemTheme = manager.useSystemTheme
        let originalIsDarkMode = manager.isDarkMode
        defer {
            manager.useSystemTheme = originalUseSystemTheme
            manager.isDarkMode = originalIsDarkMode
        }

        manager.useSystemTheme = false
        manager.isDarkMode = false

        #expect(manager.colorScheme == .light)
    }

    // MARK: - Toggle Tests

    @Test("toggleDarkMode toggles isDarkMode state")
    func toggleDarkModeTogglesState() {
        let manager = ThemeManager.shared
        let originalIsDarkMode = manager.isDarkMode
        defer { manager.isDarkMode = originalIsDarkMode }

        let beforeToggle = manager.isDarkMode

        manager.toggleDarkMode()

        #expect(manager.isDarkMode == !beforeToggle)
    }

    @Test("toggleDarkMode twice returns to original state")
    func toggleDarkModeTwiceReturnsToOriginal() {
        let manager = ThemeManager.shared
        let originalIsDarkMode = manager.isDarkMode
        defer { manager.isDarkMode = originalIsDarkMode }

        let beforeToggle = manager.isDarkMode

        manager.toggleDarkMode()
        manager.toggleDarkMode()

        #expect(manager.isDarkMode == beforeToggle)
    }

    // MARK: - setUseSystemTheme Tests

    @Test("setUseSystemTheme sets useSystemTheme to true")
    func setUseSystemThemeSetsTrue() {
        let manager = ThemeManager.shared
        let originalUseSystemTheme = manager.useSystemTheme
        defer { manager.useSystemTheme = originalUseSystemTheme }

        manager.setUseSystemTheme(true)

        #expect(manager.useSystemTheme == true)
    }

    @Test("setUseSystemTheme sets useSystemTheme to false")
    func setUseSystemThemeSetsFalse() {
        let manager = ThemeManager.shared
        let originalUseSystemTheme = manager.useSystemTheme
        defer { manager.useSystemTheme = originalUseSystemTheme }

        manager.setUseSystemTheme(false)

        #expect(manager.useSystemTheme == false)
    }

    // MARK: - Published Properties Tests

    @Test("isDarkMode is observable")
    func isDarkModeIsObservable() async throws {
        let manager = ThemeManager.shared
        let originalIsDarkMode = manager.isDarkMode
        defer { manager.isDarkMode = originalIsDarkMode }

        var cancellables = Set<AnyCancellable>()
        var receivedValues: [Bool] = []

        manager.$isDarkMode
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        manager.isDarkMode = !originalIsDarkMode

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedValues.count >= 1)
    }

    @Test("useSystemTheme is observable")
    func useSystemThemeIsObservable() async throws {
        let manager = ThemeManager.shared
        let originalUseSystemTheme = manager.useSystemTheme
        defer { manager.useSystemTheme = originalUseSystemTheme }

        var cancellables = Set<AnyCancellable>()
        var receivedValues: [Bool] = []

        manager.$useSystemTheme
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)

        manager.useSystemTheme = !originalUseSystemTheme

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedValues.count >= 1)
    }

    // MARK: - UserDefaults Persistence Tests

    @Test("isDarkMode persists to UserDefaults")
    func isDarkModePersistsToUserDefaults() {
        let manager = ThemeManager.shared
        let originalIsDarkMode = manager.isDarkMode
        defer {
            manager.isDarkMode = originalIsDarkMode
            UserDefaults.standard.set(originalIsDarkMode, forKey: "pulse.isDarkMode")
        }

        manager.isDarkMode = true

        let stored = UserDefaults.standard.bool(forKey: "pulse.isDarkMode")
        #expect(stored == true)
    }

    @Test("useSystemTheme persists to UserDefaults")
    func useSystemThemePersistsToUserDefaults() {
        let manager = ThemeManager.shared
        let originalUseSystemTheme = manager.useSystemTheme
        defer {
            manager.useSystemTheme = originalUseSystemTheme
            UserDefaults.standard.set(originalUseSystemTheme, forKey: "pulse.useSystemTheme")
        }

        manager.useSystemTheme = false

        let stored = UserDefaults.standard.bool(forKey: "pulse.useSystemTheme")
        #expect(stored == false)
    }

    // MARK: - ColorScheme Transitions

    @Test("Changing isDarkMode updates colorScheme")
    func changingIsDarkModeUpdatesColorScheme() {
        let manager = ThemeManager.shared
        let originalUseSystemTheme = manager.useSystemTheme
        let originalIsDarkMode = manager.isDarkMode
        defer {
            manager.useSystemTheme = originalUseSystemTheme
            manager.isDarkMode = originalIsDarkMode
        }

        manager.useSystemTheme = false
        manager.isDarkMode = true

        #expect(manager.colorScheme == .dark)

        manager.isDarkMode = false

        #expect(manager.colorScheme == .light)
    }

    @Test("Changing useSystemTheme updates colorScheme")
    func changingUseSystemThemeUpdatesColorScheme() {
        let manager = ThemeManager.shared
        let originalUseSystemTheme = manager.useSystemTheme
        let originalIsDarkMode = manager.isDarkMode
        defer {
            manager.useSystemTheme = originalUseSystemTheme
            manager.isDarkMode = originalIsDarkMode
        }

        manager.useSystemTheme = false
        manager.isDarkMode = true

        #expect(manager.colorScheme == .dark)

        manager.useSystemTheme = true

        #expect(manager.colorScheme == nil)
    }
}
