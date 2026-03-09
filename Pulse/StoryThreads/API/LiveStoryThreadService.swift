import Combine
import EntropyCore
import Foundation
import SwiftData

/// Live implementation of `StoryThreadService` using SwiftData for persistence
/// and keyword/category-based article clustering.
final class LiveStoryThreadService: StoryThreadService {
    private let modelContainer: ModelContainer
    private let llmService: LLMService?

    init(llmService: LLMService? = nil) {
        let schema = Schema([StoryThread.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Fall back to default configuration if custom one fails
            do {
                modelContainer = try ModelContainer(for: schema)
            } catch {
                fatalError("Failed to create ModelContainer for StoryThread: \(error)")
            }
        }
        self.llmService = llmService
    }

    func fetchThreads(for articleID: String) -> AnyPublisher<[StoryThread], Error> {
        Future { [weak self] promise in
            Task { @MainActor [weak self] in
                guard let self else {
                    promise(.success([]))
                    return
                }
                do {
                    let context = self.modelContainer.mainContext
                    let descriptor = FetchDescriptor<StoryThread>()
                    let threads = try context.fetch(descriptor)
                    let matching = threads.filter { $0.articleIDs.contains(articleID) }
                    promise(.success(matching))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchFollowedThreads() -> AnyPublisher<[StoryThread], Error> {
        Future { [weak self] promise in
            Task { @MainActor [weak self] in
                guard let self else {
                    promise(.success([]))
                    return
                }
                do {
                    let context = self.modelContainer.mainContext
                    let descriptor = FetchDescriptor<StoryThread>(
                        predicate: #Predicate { $0.isFollowing == true },
                        sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
                    )
                    let threads = try context.fetch(descriptor)
                    promise(.success(threads))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func followThread(id: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            Task { @MainActor [weak self] in
                guard let self else {
                    promise(.success(()))
                    return
                }
                do {
                    let context = self.modelContainer.mainContext
                    let descriptor = FetchDescriptor<StoryThread>(
                        predicate: #Predicate { $0.id == id }
                    )
                    if let thread = try context.fetch(descriptor).first {
                        thread.isFollowing = true
                        try context.save()
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func unfollowThread(id: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            Task { @MainActor [weak self] in
                guard let self else {
                    promise(.success(()))
                    return
                }
                do {
                    let context = self.modelContainer.mainContext
                    let descriptor = FetchDescriptor<StoryThread>(
                        predicate: #Predicate { $0.id == id }
                    )
                    if let thread = try context.fetch(descriptor).first {
                        thread.isFollowing = false
                        try context.save()
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func generateThreadSummary(thread: StoryThread) -> AnyPublisher<String, Error> {
        guard let llmService else {
            return Fail(error: StoryThreadError.llmNotAvailable)
                .eraseToAnyPublisher()
        }

        let prompt = """
        Summarize this developing news story in 2-3 sentences. \
        The story is titled "\(thread.title)" in the \(thread.category) category \
        and contains \(thread.articleIDs.count) related articles.
        """

        return llmService.generate(
            prompt: prompt,
            systemPrompt: "You are a concise news summarizer. Provide brief, factual summaries.",
            config: .default
        )
        .eraseToAnyPublisher()
    }

    func clusterArticles(from articles: [Article]) -> AnyPublisher<[StoryThread], Error> {
        Future { [weak self] promise in
            Task { @MainActor [weak self] in
                guard let self else {
                    promise(.success([]))
                    return
                }
                let threads = self.clusterByCategory(articles: articles)
                // Persist new threads
                let context = self.modelContainer.mainContext
                for thread in threads {
                    context.insert(thread)
                }
                try? context.save()
                promise(.success(threads))
            }
        }
        .eraseToAnyPublisher()
    }

    func markThreadAsRead(id: UUID) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            Task { @MainActor [weak self] in
                guard let self else {
                    promise(.success(()))
                    return
                }
                do {
                    let context = self.modelContainer.mainContext
                    let descriptor = FetchDescriptor<StoryThread>(
                        predicate: #Predicate { $0.id == id }
                    )
                    if let thread = try context.fetch(descriptor).first {
                        thread.lastReadAt = .now
                        try context.save()
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Private

    /// Groups articles by category and extracts common keywords to form threads.
    private func clusterByCategory(articles: [Article]) -> [StoryThread] {
        var categoryGroups: [String: [Article]] = [:]

        for article in articles {
            let category = article.category?.rawValue ?? "general"
            categoryGroups[category, default: []].append(article)
        }

        return categoryGroups.compactMap { category, groupArticles -> StoryThread? in
            guard groupArticles.count >= 2 else { return nil }

            // Use the most common significant words from titles as thread title
            let threadTitle = extractThreadTitle(from: groupArticles)
            let articleIDs = groupArticles.map(\.id)

            return StoryThread(
                title: threadTitle,
                summary: "Developing story with \(articleIDs.count) related articles.",
                articleIDs: articleIDs,
                category: category,
                createdAt: groupArticles.map(\.publishedAt).min() ?? .now,
                updatedAt: groupArticles.map(\.publishedAt).max() ?? .now
            )
        }
    }

    /// Extracts a representative title from a group of articles.
    private func extractThreadTitle(from articles: [Article]) -> String {
        let stopWords: Set = [
            "the", "a", "an", "is", "are", "was", "were", "in", "on", "at",
            "to", "for", "of", "with", "by", "from", "and", "or", "but", "not",
            "this", "that", "it", "as", "be", "has", "have", "had", "will",
        ]

        var wordCounts: [String: Int] = [:]
        for article in articles {
            let words = article.title.lowercased()
                .components(separatedBy: .alphanumerics.inverted)
                .filter { $0.count > 2 && !stopWords.contains($0) }
            for word in Set(words) {
                wordCounts[word, default: 0] += 1
            }
        }

        let commonWords = wordCounts
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .prefix(4)
            .map(\.key)
            .map { $0.capitalized }

        if commonWords.isEmpty {
            return articles.first?.title ?? "News Thread"
        }
        return commonWords.joined(separator: " ")
    }
}

// MARK: - Error

enum StoryThreadError: LocalizedError {
    case llmNotAvailable
    case threadNotFound

    var errorDescription: String? {
        switch self {
        case .llmNotAvailable:
            return "AI model is not available"
        case .threadNotFound:
            return "Story thread not found"
        }
    }
}
