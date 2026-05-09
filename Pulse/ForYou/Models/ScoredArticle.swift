import Foundation

/// An article paired with its computed personalization score and the
/// matched topics that contributed to that score.
///
/// `matchedTopics` is preserved separately so the UI can answer
/// "Why am I seeing this?" without recomputing the join.
struct ScoredArticle: Equatable {
    let article: Article
    /// Computed score in `[0, 1]`. Higher = better match for the profile.
    let score: Double
    /// `topicID`s from the user's profile that matched this article
    /// (intersection between profile and article tags).
    let matchedTopics: [String]
}
