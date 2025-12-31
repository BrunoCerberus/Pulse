import EntropyCore
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    private let serviceLocator: ServiceLocator

    @State private var isPaywallPresented = false
    @State private var isPremium = false

    init(serviceLocator: ServiceLocator) {
        self.serviceLocator = serviceLocator
        _viewModel = StateObject(wrappedValue: SettingsViewModel(serviceLocator: serviceLocator))
    }

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()

            List {
                SettingsAccountSection(
                    currentUser: viewModel.viewState.currentUser,
                    onSignOutTapped: { viewModel.handle(event: .onSignOutTapped) }
                )

                SettingsPremiumSection(
                    isPremium: isPremium,
                    onUpgradeTapped: { isPaywallPresented = true }
                )

                topicsSection
                notificationsSection
                appearanceSection

                SettingsMutedContentSection(
                    mutedSources: viewModel.viewState.mutedSources,
                    mutedKeywords: viewModel.viewState.mutedKeywords,
                    newMutedSource: $viewModel.newMutedSource,
                    newMutedKeyword: $viewModel.newMutedKeyword,
                    onAddMutedSource: { viewModel.handle(event: .onAddMutedSource) },
                    onRemoveMutedSource: { viewModel.handle(event: .onRemoveMutedSource($0)) },
                    onAddMutedKeyword: { viewModel.handle(event: .onAddMutedKeyword) },
                    onRemoveMutedKeyword: { viewModel.handle(event: .onRemoveMutedKeyword($0)) }
                )

                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .alert("Clear Reading History?", isPresented: Binding(
            get: { viewModel.viewState.showClearHistoryConfirmation },
            set: { _ in viewModel.handle(event: .onCancelClearHistory) }
        )) {
            Button("Cancel", role: .cancel) {
                HapticManager.shared.tap()
                viewModel.handle(event: .onCancelClearHistory)
            }
            Button("Clear", role: .destructive) {
                HapticManager.shared.notification(.warning)
                viewModel.handle(event: .onConfirmClearHistory)
            }
        } message: {
            Text("This will remove all articles from your reading history. This action cannot be undone.")
        }
        .alert("Sign Out?", isPresented: Binding(
            get: { viewModel.viewState.showSignOutConfirmation },
            set: { _ in viewModel.handle(event: .onCancelSignOut) }
        )) {
            Button("Cancel", role: .cancel) {
                HapticManager.shared.tap()
                viewModel.handle(event: .onCancelSignOut)
            }
            Button("Sign Out", role: .destructive) {
                HapticManager.shared.notification(.warning)
                viewModel.handle(event: .onConfirmSignOut)
            }
        } message: {
            Text("Are you sure you want to sign out of your account?")
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
            checkPremiumStatus()
        }
        .sheet(
            isPresented: $isPaywallPresented,
            onDismiss: { checkPremiumStatus() },
            content: { PaywallView(viewModel: PaywallViewModel(serviceLocator: serviceLocator)) }
        )
    }

    private func checkPremiumStatus() {
        do {
            let storeKitService = try serviceLocator.retrieve(StoreKitService.self)
            isPremium = storeKitService.isPremium
        } catch {
            isPremium = false
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

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                viewModel.handle(event: .onClearReadingHistory)
            } label: {
                Label("Clear Reading History", systemImage: "trash")
            }
            .accessibilityIdentifier("clearReadingHistoryButton")
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

enum SettingsCoordinator {
    static func start(serviceLocator: ServiceLocator) -> some View {
        SettingsView(serviceLocator: serviceLocator)
    }
}
