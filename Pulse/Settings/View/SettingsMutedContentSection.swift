import EntropyCore
import SwiftUI

struct SettingsMutedContentSection: View {
    private enum Constants {
        static var contentFilters: String {
            AppLocalization.localized("settings.content_filters")
        }

        static var contentFiltersDescription: String {
            AppLocalization.localized("settings.content_filters.description")
        }

        static var mutedSources: String {
            AppLocalization.localized("settings.muted_sources")
        }

        static var addSource: String {
            AppLocalization.localized("settings.muted_sources.add")
        }

        static var addSourceAction: String {
            AppLocalization.localized("settings.muted_sources.add_action")
        }

        static var removeSourceAction: String {
            AppLocalization.localized("settings.muted_sources.remove_action")
        }

        static var mutedKeywords: String {
            AppLocalization.localized("settings.muted_keywords")
        }

        static var addKeyword: String {
            AppLocalization.localized("settings.muted_keywords.add")
        }

        static var addKeywordAction: String {
            AppLocalization.localized("settings.muted_keywords.add_action")
        }

        static var removeKeywordAction: String {
            AppLocalization.localized("settings.muted_keywords.remove_action")
        }
    }

    let mutedSources: [String]
    let mutedKeywords: [String]
    @Binding var newMutedSource: String
    @Binding var newMutedKeyword: String
    let onAddMutedSource: () -> Void
    let onRemoveMutedSource: (String) -> Void
    let onAddMutedKeyword: () -> Void
    let onRemoveMutedKeyword: (String) -> Void

    var body: some View {
        Section {
            mutedSourcesGroup
            mutedKeywordsGroup
        } header: {
            Text(Constants.contentFilters)
        } footer: {
            Text(Constants.contentFiltersDescription)
        }
    }

    private var mutedSourcesGroup: some View {
        DisclosureGroup("\(Constants.mutedSources) (\(mutedSources.count))") {
            HStack {
                TextField(Constants.addSource, text: $newMutedSource)
                    .textFieldStyle(.roundedBorder)

                Button {
                    onAddMutedSource()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel(Constants.addSourceAction)
                .disabled(newMutedSource.isEmpty)
            }

            ForEach(mutedSources, id: \.self) { source in
                HStack {
                    Text(source)
                    Spacer()
                    Button {
                        onRemoveMutedSource(source)
                    } label: {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(Constants.removeSourceAction)
                }
            }
        }
    }

    private var mutedKeywordsGroup: some View {
        DisclosureGroup("\(Constants.mutedKeywords) (\(mutedKeywords.count))") {
            HStack {
                TextField(Constants.addKeyword, text: $newMutedKeyword)
                    .textFieldStyle(.roundedBorder)

                Button {
                    onAddMutedKeyword()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel(Constants.addKeywordAction)
                .disabled(newMutedKeyword.isEmpty)
            }

            ForEach(mutedKeywords, id: \.self) { keyword in
                HStack {
                    Text(keyword)
                    Spacer()
                    Button {
                        onRemoveMutedKeyword(keyword)
                    } label: {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(Constants.removeKeywordAction)
                }
            }
        }
    }
}

#Preview {
    SettingsMutedContentSection(
        mutedSources: ["Source 1", "Source 2"],
        mutedKeywords: ["Keyword 1", "Keyword 2"],
        newMutedSource: .constant(""),
        newMutedKeyword: .constant(""),
        onAddMutedSource: {},
        onRemoveMutedSource: { _ in },
        onAddMutedKeyword: {},
        onRemoveMutedKeyword: { _ in }
    )
    .preferredColorScheme(.dark)
}
