import Combine
import SwiftUI

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: Keys.isDarkMode)
        }
    }

    @Published var useSystemTheme: Bool {
        didSet {
            UserDefaults.standard.set(useSystemTheme, forKey: Keys.useSystemTheme)
        }
    }

    var colorScheme: ColorScheme? {
        useSystemTheme ? nil : (isDarkMode ? .dark : .light)
    }

    private enum Keys {
        static let isDarkMode = "pulse.isDarkMode"
        static let useSystemTheme = "pulse.useSystemTheme"
    }

    private init() {
        useSystemTheme = UserDefaults.standard.bool(forKey: Keys.useSystemTheme)
        isDarkMode = UserDefaults.standard.bool(forKey: Keys.isDarkMode)

        if !UserDefaults.standard.bool(forKey: "pulse.hasLaunched") {
            UserDefaults.standard.set(true, forKey: "pulse.hasLaunched")
            UserDefaults.standard.set(true, forKey: Keys.useSystemTheme)
            useSystemTheme = true
        }
    }

    func toggleDarkMode() {
        isDarkMode.toggle()
    }

    func setUseSystemTheme(_ value: Bool) {
        useSystemTheme = value
    }
}
