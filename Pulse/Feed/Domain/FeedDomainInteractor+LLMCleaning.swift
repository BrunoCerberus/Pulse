import Combine
import EntropyCore
import Foundation

// MARK: - Article Fetching

extension FeedDomainInteractor {
    func fetchArticlesFromAllCategories(newsService: NewsService) async -> [Article] {
        var allArticles: [Article] = []

        await withTaskGroup(of: [Article].self) { group in
            for category in NewsCategory.allCases {
                group.addTask {
                    do {
                        let articles = try await withCheckedThrowingContinuation { continuation in
                            var cancellable: AnyCancellable?
                            cancellable = newsService
                                .fetchTopHeadlines(category: category, language: "en", country: "us", page: 1)
                                .first()
                                .sink(
                                    receiveCompletion: { completion in
                                        if case let .failure(error) = completion {
                                            continuation.resume(throwing: error)
                                        }
                                        cancellable?.cancel()
                                    },
                                    receiveValue: { articles in
                                        continuation.resume(returning: articles)
                                    }
                                )
                        }
                        return Array(articles.prefix(10))
                    } catch {
                        Logger.shared.warning(
                            "Failed to fetch \(category.displayName): \(error)",
                            category: "FeedDomainInteractor"
                        )
                        return []
                    }
                }
            }

            for await articles in group {
                guard !Task.isCancelled else { return }
                allArticles.append(contentsOf: articles)
            }
        }

        allArticles.sort { $0.publishedAt > $1.publishedAt }
        return allArticles
    }
}

// MARK: - LLM Output Cleaning

extension FeedDomainInteractor {
    nonisolated func cleanLLMOutput(_ text: String) -> String {
        var cleaned = text

        // Remove null characters (LLM sometimes outputs these between tokens)
        cleaned = cleaned.replacingOccurrences(of: "\0", with: "")

        // Remove chat template markers (ChatML + general)
        let markers = [
            "<|system|>", "<|user|>", "<|assistant|>", "<|end|>",
            "<|im_start|>", "<|im_end|>", "</s>", "<s>",
        ]
        for marker in markers {
            cleaned = cleaned.replacingOccurrences(of: marker, with: "")
        }

        // Remove common instruction artifacts (case-insensitive, at start)
        let prefixes = [
            "here's the digest:", "here is the digest:", "digest:", "here's your daily digest:",
            "here is your daily digest:", "sure, here", "sure! here", "here's your news digest:",
            "here are the summaries:", "here is a summary:",
        ]
        let lowercased = cleaned.lowercased()
        for prefix in prefixes where lowercased.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count))
            break
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
