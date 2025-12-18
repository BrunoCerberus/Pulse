import Foundation

enum APIKeysProvider {
    static var newsAPIKey: String {
        ProcessInfo.processInfo.environment["NEWS_API_KEY"] ?? "23883adcb2784b0f818397b307401ae3"
    }

    static var guardianAPIKey: String {
        ProcessInfo.processInfo.environment["GUARDIAN_API_KEY"] ?? ""
    }

    static var gnewsAPIKey: String {
        ProcessInfo.processInfo.environment["GNEWS_API_KEY"] ?? ""
    }
}
