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
            Text(String(localized: "settings.content_filters"))
        } footer: {
            Text(String(localized: "settings.content_filters.description"))
        }
    }

    private var mutedSourcesGroup: some View {
        DisclosureGroup("Muted Sources (\(mutedSources.count))") {
            HStack {
                TextField("Add source...", text: $newMutedSource)
                    .textFieldStyle(.roundedBorder)

                Button {
                    onAddMutedSource()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Add source")
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
                    .accessibilityLabel("Remove source")
                }
            }
        }
    }

    private var mutedKeywordsGroup: some View {
        DisclosureGroup("Muted Keywords (\(mutedKeywords.count))") {
            HStack {
                TextField("Add keyword...", text: $newMutedKeyword)
                    .textFieldStyle(.roundedBorder)

                Button {
                    onAddMutedKeyword()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Add keyword")
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
                    .accessibilityLabel("Remove keyword")
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
}
