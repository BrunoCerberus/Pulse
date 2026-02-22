import SwiftUI

struct SettingsMutedContentSection: View {
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
            Text(AppLocalization.shared.localized("settings.content_filters"))
        } footer: {
            Text(AppLocalization.shared.localized("settings.content_filters.description"))
        }
    }

    private var mutedSourcesGroup: some View {
        DisclosureGroup("\(AppLocalization.shared.localized("settings.muted_sources")) (\(mutedSources.count))") {
            HStack {
                TextField(AppLocalization.shared.localized("settings.muted_sources.add"), text: $newMutedSource)
                    .textFieldStyle(.roundedBorder)

                Button {
                    onAddMutedSource()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel(AppLocalization.shared.localized("settings.muted_sources.add_action"))
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
                    .accessibilityLabel(AppLocalization.shared.localized("settings.muted_sources.remove_action"))
                }
            }
        }
    }

    private var mutedKeywordsGroup: some View {
        DisclosureGroup("\(AppLocalization.shared.localized("settings.muted_keywords")) (\(mutedKeywords.count))") {
            HStack {
                TextField(AppLocalization.shared.localized("settings.muted_keywords.add"), text: $newMutedKeyword)
                    .textFieldStyle(.roundedBorder)

                Button {
                    onAddMutedKeyword()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel(AppLocalization.shared.localized("settings.muted_keywords.add_action"))
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
                    .accessibilityLabel(AppLocalization.shared.localized("settings.muted_keywords.remove_action"))
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
