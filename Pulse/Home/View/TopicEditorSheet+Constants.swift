import Foundation

// MARK: - Constants

extension TopicEditorSheet {
    enum Constants {
        static var title: String {
            AppLocalization.localized("home.edit_topics.title")
        }

        static var description: String {
            AppLocalization.localized("home.edit_topics.description")
        }

        static var done: String {
            AppLocalization.localized("common.done")
        }

        static var unfollowHint: String {
            AppLocalization.localized("topic_editor.unfollow_hint")
        }

        static var followHint: String {
            AppLocalization.localized("topic_editor.follow_hint")
        }
    }
}
