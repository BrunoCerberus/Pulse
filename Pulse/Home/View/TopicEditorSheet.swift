import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.localized("home.edit_topics.title")
    }

    static var description: String {
        AppLocalization.localized("home.edit_topics.description")
    }

    static var done: String {
        AppLocalization.localized("common.done")
    }
}

// MARK: - TopicEditorSheet

/// Sheet for managing followed topics.
///
/// Displays all available topics with checkmarks for followed ones.
/// Users can tap to toggle topics on/off.
struct TopicEditorSheet: View {
    let allTopics: [NewsCategory]
    let followedTopics: [NewsCategory]
    let onToggleTopic: (NewsCategory) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(allTopics) { topic in
                        Button {
                            HapticManager.shared.selectionChanged()
                            onToggleTopic(topic)
                        } label: {
                            HStack {
                                Label(topic.displayName, systemImage: topic.icon)
                                    .foregroundStyle(topic.color)

                                Spacer()

                                if followedTopics.contains(topic) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .fontWeight(.semibold)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(followedTopics.contains(topic) ? .isSelected : [])
                        .accessibilityHint(
                            followedTopics.contains(topic)
                                ? AppLocalization.localized("topic_editor.unfollow_hint")
                                : AppLocalization.localized("topic_editor.follow_hint")
                        )
                    }
                } footer: {
                    Text(Constants.description)
                }
            }
            .navigationTitle(Constants.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Constants.done) {
                        HapticManager.shared.tap()
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview("With Selections") {
    TopicEditorSheet(
        allTopics: NewsCategory.allCases,
        followedTopics: [.technology, .science, .business],
        onToggleTopic: { _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    TopicEditorSheet(
        allTopics: NewsCategory.allCases,
        followedTopics: [],
        onToggleTopic: { _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("All Selected") {
    TopicEditorSheet(
        allTopics: NewsCategory.allCases,
        followedTopics: NewsCategory.allCases,
        onToggleTopic: { _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
