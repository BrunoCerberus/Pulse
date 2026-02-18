import Combine
import EntropyCore
import Foundation

/// Media service that fetches videos and podcasts from Supabase backend.
///
/// Fetches media content from the RSS aggregator backend which provides
/// videos from YouTube channels and podcasts from various podcast feeds.
final class LiveMediaService: APIRequest, MediaService {
    private let useSupabase: Bool

    override init() {
        useSupabase = SupabaseConfig.isConfigured
        super.init()

        if useSupabase {
            Logger.shared.service("LiveMediaService: using Supabase backend", level: .info)
        } else {
            Logger.shared.service("LiveMediaService: Supabase not configured", level: .warning)
        }
    }

    func fetchMedia(type: MediaType?, language: String, page: Int) -> AnyPublisher<[Article], Error> {
        guard useSupabase else {
            Logger.shared.service("LiveMediaService: Supabase not configured, returning empty", level: .warning)
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        let categorySlug = type?.categorySlug
        return fetchRequest(
            target: SupabaseAPI.media(language: language, type: categorySlug, page: page, pageSize: 20),
            dataType: [SupabaseArticle].self
        )
        .map { $0.map { $0.toArticle() } }
        .handleEvents(receiveOutput: { articles in
            let typeStr = type?.displayName ?? "all media"
            Logger.shared.service("LiveMediaService: Fetched \(articles.count) \(typeStr)", level: .debug)
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    func fetchFeaturedMedia(type: MediaType?, language: String) -> AnyPublisher<[Article], Error> {
        guard useSupabase else {
            Logger.shared.service("LiveMediaService: Supabase not configured, returning empty", level: .warning)
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        let categorySlug = type?.categorySlug
        return fetchRequest(
            target: SupabaseAPI.featuredMedia(language: language, type: categorySlug, limit: 10),
            dataType: [SupabaseArticle].self
        )
        .map { $0.map { $0.toArticle() } }
        .handleEvents(receiveOutput: { articles in
            let typeStr = type?.displayName ?? "all media"
            Logger.shared.service("LiveMediaService: Fetched \(articles.count) featured \(typeStr)", level: .debug)
        })
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
