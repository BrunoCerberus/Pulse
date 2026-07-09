import EntropyCore
import SwiftUI

/// Settings screen for the on-device personalization profile.
///
/// Shows every learned interest topic with its accumulated weight and
/// provenance, lets the user remove topics individually (swipe), and
/// offers a destructive "Reset profile" affordance.
struct ForYouSettingsView: View {
    @ObservedObject var viewModel: ForYouSettingsViewModel

    var body: some View {
        ZStack {
            LinearGradient.subtleBackground
                .ignoresSafeArea()
            content
        }
        .navigationTitle(Constants.navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !viewModel.viewState.rows.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        HapticManager.shared.tap()
                        viewModel.handle(event: .onResetTapped)
                    } label: {
                        Text(Constants.resetButton)
                            .foregroundStyle(Color.Semantic.error)
                    }
                    .accessibilityLabel(Constants.resetButton)
                }
            }
        }
        .alert(
            Constants.resetConfirmTitle,
            isPresented: Binding(
                get: { viewModel.viewState.showResetConfirmation },
                set: { newValue in
                    if !newValue {
                        viewModel.handle(event: .onResetCancelled)
                    }
                }
            )
        ) {
            Button(Constants.resetCancelAction, role: .cancel) {
                viewModel.handle(event: .onResetCancelled)
            }
            Button(Constants.resetConfirmAction, role: .destructive) {
                viewModel.handle(event: .onResetConfirmed)
            }
        } message: {
            Text(Constants.resetConfirmMessage)
        }
        .task {
            viewModel.handle(event: .onAppear)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.showEmptyState {
            emptyStateView
        } else {
            topicsList
        }
    }

    private var topicsList: some View {
        List {
            Section {
                ForEach(viewModel.viewState.rows) { row in
                    rowView(for: row)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.handle(event: .onRemoveTopic(topicID: row.id))
                            } label: {
                                Label(Constants.deleteAction, systemImage: "trash")
                            }
                        }
                }
            } header: {
                Text(Constants.headerSubtitle)
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func rowView(for row: ForYouTopicRow) -> some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(row.displayName)
                    .font(Typography.bodyLarge)
                    .foregroundStyle(.primary)
                Text(row.sourceLabel)
                    .font(Typography.captionSmall)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: Spacing.sm)
            Text(row.weightLabel)
                .font(Typography.captionLarge.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.displayName), \(row.sourceLabel), weight \(row.weightLabel)")
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            Constants.emptyTitle,
            systemImage: "sparkles",
            description: Text(Constants.emptyMessage)
        )
    }
}

#Preview {
    NavigationStack {
        ForYouSettingsView(viewModel: ForYouSettingsViewModel(serviceLocator: .preview))
    }
}
