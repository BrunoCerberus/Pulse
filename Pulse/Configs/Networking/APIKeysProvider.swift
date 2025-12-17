import Foundation

enum APIKeysProvider {
    static var newsAPIKey: String {
        ProcessInfo.processInfo.environment["NEWS_API_KEY"] ?? ""
    }

    static var guardianAPIKey: String {
        ProcessInfo.processInfo.environment["GUARDIAN_API_KEY"] ?? ""
    }

    static var gnewsAPIKey: String {
        ProcessInfo.processInfo.environment["GNEWS_API_KEY"] ?? ""
    }
}
