import Combine
import Foundation

/// Protocol for managing story threads — grouping related articles into evolving story arcs.
protocol StoryThreadService {
    /// Finds threads that contain the given article.
    /// - Parameter articleID: The article ID to search for.
    /// - Returns: Publisher emitting threads containing the article.
    func fetchThreads(for articleID: String) -> AnyPublisher<[StoryThread], Error>

    /// Fetches all threads the user is following.
    /// - Returns: Publisher emitting followed threads, ordered by most recently updated.
    func fetchFollowedThreads() -> AnyPublisher<[StoryThread], Error>

    /// Follows a thread so the user receives updates.
    /// - Parameter id: The thread's unique identifier.
    func followThread(id: UUID) -> AnyPublisher<Void, Error>

    /// Unfollows a thread.
    /// - Parameter id: The thread's unique identifier.
    func unfollowThread(id: UUID) -> AnyPublisher<Void, Error>

    /// Generates an AI summary of the story so far (Premium).
    /// - Parameter thread: The thread to summarize.
    /// - Returns: Publisher emitting the generated summary text.
    func generateThreadSummary(thread: StoryThread) -> AnyPublisher<String, Error>

    /// Groups articles into story threads by similarity.
    /// - Parameter articles: The articles to cluster.
    /// - Returns: Publisher emitting discovered threads.
    func clusterArticles(from articles: [Article]) -> AnyPublisher<[StoryThread], Error>

    /// Marks a thread as read at the current time.
    /// - Parameter id: The thread's unique identifier.
    func markThreadAsRead(id: UUID) -> AnyPublisher<Void, Error>
}
