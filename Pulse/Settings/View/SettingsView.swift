import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    private let serviceLocator: ServiceLocator

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        _viewModel = StateObject(wrappedValue: SettingsViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        List {
            topicsSection
            notificationsSection
            appearanceSection
            mutedContentSection
            dataSection
            aboutSection
        }
        .navigationTitle("Settings")
        .alert("Clear Reading History?", isPresented: Binding(
            get: { viewModel.viewState.showClearHistoryConfirmation },
            set: { _ in viewModel.handle(event: .onCancelClearHistory) }
        )) {
            Button("Cancel", role: .cancel) {
                viewModel.handle(event: .onCancelClearHistory)
            }
            Button("Clear", role: .destructive) {
                viewModel.handle(event: .onConfirmClearHistory)
            }
        } message: {
            Text("This will remove all articles from your reading history. This action cannot be undone.")
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
    }

    private var topicsSection: some View {
        Section {
            ForEach(viewModel.viewState.allTopics) { topic in
                Button {
                    viewModel.handle(event: .onToggleTopic(topic))
                } label: {
                    HStack {
                        Label(topic.displayName, systemImage: topic.icon)
                            .foregroundStyle(topic.color)

                        Spacer()

                        if viewModel.viewState.followedTopics.contains(topic) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Followed Topics")
        } footer: {
            Text("Articles from followed topics will appear in your For You feed.")
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Enable Notifications", isOn: Binding(
                get: { viewModel.viewState.notificationsEnabled },
                set: { viewModel.handle(event: .onToggleNotifications($0)) }
            ))

            Toggle("Breaking News Alerts", isOn: Binding(
                get: { viewModel.viewState.breakingNewsEnabled },
                set: { viewModel.handle(event: .onToggleBreakingNews($0)) }
            ))
            .disabled(!viewModel.viewState.notificationsEnabled)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Toggle("Use System Theme", isOn: Binding(
                get: { viewModel.viewState.useSystemTheme },
                set: { viewModel.handle(event: .onToggleSystemTheme($0)) }
            ))

            if !viewModel.viewState.useSystemTheme {
                Toggle("Dark Mode", isOn: Binding(
                    get: { viewModel.viewState.isDarkMode },
                    set: { viewModel.handle(event: .onToggleDarkMode($0)) }
                ))
            }
        }
    }

    private var mutedContentSection: some View {
        Section {
            DisclosureGroup("Muted Sources (\(viewModel.viewState.mutedSources.count))") {
                HStack {
                    TextField("Add source...", text: $viewModel.newMutedSource)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        viewModel.handle(event: .onAddMutedSource)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(viewModel.newMutedSource.isEmpty)
                }

                ForEach(viewModel.viewState.mutedSources, id: \.self) { source in
                    HStack {
                        Text(source)
                        Spacer()
                        Button {
                            viewModel.handle(event: .onRemoveMutedSource(source))
                        } label: {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            DisclosureGroup("Muted Keywords (\(viewModel.viewState.mutedKeywords.count))") {
                HStack {
                    TextField("Add keyword...", text: $viewModel.newMutedKeyword)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        viewModel.handle(event: .onAddMutedKeyword)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(viewModel.newMutedKeyword.isEmpty)
                }

                ForEach(viewModel.viewState.mutedKeywords, id: \.self) { keyword in
                    HStack {
                        Text(keyword)
                        Spacer()
                        Button {
                            viewModel.handle(event: .onRemoveMutedKeyword(keyword))
                        } label: {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Content Filters")
        } footer: {
            Text("Muted sources and keywords will be hidden from all feeds.")
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                viewModel.handle(event: .onClearReadingHistory)
            } label: {
                Label("Clear Reading History", systemImage: "trash")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://github.com/BrunoCerberus/Pulse")!) {
                Label("View on GitHub", systemImage: "link")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(serviceLocator: .preview)
    }
}

struct SettingsCoordinator {
    static func start(serviceLocator: ServiceLocator) -> some View {
        SettingsView(serviceLocator: serviceLocator)
    }
}
