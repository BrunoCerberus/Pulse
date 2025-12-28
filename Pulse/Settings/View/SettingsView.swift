import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    private let serviceLocator: ServiceLocator

    /// Whether the paywall sheet is presented
    @State private var isPaywallPresented = false

    /// Whether the user has an active premium subscription
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
                accountSection
                premiumSection
                topicsSection
                notificationsSection
                appearanceSection
                mutedContentSection
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

    /// Check premium subscription status
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

    private var premiumSection: some View {
        Section {
            Button {
                if !isPremium {
                    HapticManager.shared.buttonPress()
                    isPaywallPresented = true
                }
            } label: {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(isPremium ? Color.yellow.opacity(0.2) : Color.orange.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: isPremium ? "crown.fill" : "crown")
                            .font(.system(size: IconSize.lg))
                            .foregroundStyle(isPremium ? .yellow : .orange)
                    }
                    .glowEffect(color: isPremium ? .yellow : .clear, radius: 8)

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(isPremium ? Localizable.paywall.premiumActive : Localizable.paywall.goPremium)
                            .font(Typography.headlineMedium)
                            .foregroundStyle(.primary)

                        Text(isPremium ? Localizable.paywall.fullAccess : Localizable.paywall.unlockFeatures)
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if isPremium {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: IconSize.lg))
                            .foregroundStyle(Color.Semantic.success)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
            .buttonStyle(.plain)
            .disabled(isPremium)
        } header: {
            Text("Subscription")
                .font(Typography.captionLarge)
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

    private var accountSection: some View {
        Section {
            if let user = viewModel.viewState.currentUser {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Text(userInitial(for: user))
                            .font(Typography.headlineLarge)
                            .foregroundStyle(.blue)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        if let displayName = user.displayName {
                            Text(displayName)
                                .font(Typography.headlineMedium)
                                .foregroundStyle(.primary)
                        }

                        if let email = user.email {
                            Text(email)
                                .font(Typography.captionLarge)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, Spacing.xs)

                Button(role: .destructive) {
                    HapticManager.shared.buttonPress()
                    viewModel.handle(event: .onSignOutTapped)
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } header: {
            Text("Account")
                .font(Typography.captionLarge)
        }
    }

    private func userInitial(for user: AuthUser) -> String {
        if let displayName = user.displayName, let first = displayName.first {
            return String(first).uppercased()
        }
        if let email = user.email, let first = email.first {
            return String(first).uppercased()
        }
        return "U"
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
