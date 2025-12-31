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
            Text("Content Filters")
        } footer: {
            Text("Muted sources and keywords will be hidden from all feeds.")
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
                }
            }
        }
    }
}
