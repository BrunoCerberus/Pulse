import SwiftUI

// MARK: - Constants

private enum Constants {
    static let title = "Collections"
    static let featuredSection = "Featured"
    static let myCollectionsSection = "My Collections"
    static let emptyTitle = "No Collections Yet"
    static let emptyMessage = "Create your first collection to organize articles by topic."
    static let emptyUserTitle = "No Personal Collections"
    static let emptyUserMessage = "Tap + to create your first collection"
    static let errorTitle = "Something went wrong"
    static let tryAgain = "Try Again"
    static let createNew = "New Collection"
    static let premiumSection = "Premium Collections"
    static let premiumMessage = "Unlock AI-curated collections"
}

// MARK: - CollectionsView

struct CollectionsView<R: CollectionsNavigationRouter>: View {
    private var router: R

    @ObservedObject var viewModel: CollectionsViewModel

    init(router: R, viewModel: CollectionsViewModel) {
        self.router = router
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            content
        }
        .navigationTitle(Constants.title)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticManager.shared.tap()
                    viewModel.handle(event: .onCreateCollectionTapped)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: IconSize.md))
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Create Collection")
                .accessibilityHint("Create a new personal collection")
            }
        }
        .refreshable {
            HapticManager.shared.refresh()
            viewModel.handle(event: .onRefresh)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.viewState.showCreateSheet },
            set: { _ in viewModel.handle(event: .onCreateCollectionDismissed) }
        )) {
            CreateCollectionSheet { name, description in
                viewModel.handle(event: .onCreateCollection(name: name, description: description))
            }
        }
        .alert(
            "Delete Collection",
            isPresented: Binding(
                get: { viewModel.viewState.collectionToDelete != nil },
                set: { if !$0 { viewModel.handle(event: .onDeleteCollectionCancelled) } }
            ),
            presenting: viewModel.viewState.collectionToDelete
        ) { _ in
            Button("Cancel", role: .cancel) {
                viewModel.handle(event: .onDeleteCollectionCancelled)
            }
            Button("Delete", role: .destructive) {
                viewModel.handle(event: .onDeleteCollectionConfirmed)
            }
        } message: { collection in
            Text("Are you sure you want to delete \"\(collection.name)\"? This action cannot be undone.")
        }
        .onAppear {
            viewModel.handle(event: .onAppear)
        }
        .onChange(of: viewModel.viewState.selectedCollection) { _, newValue in
            if let collection = newValue {
                router.route(navigationEvent: .collectionDetail(collection))
                viewModel.handle(event: .onCollectionNavigated)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient.subtleBackground
    }

    // MARK: - Content Views

    @ViewBuilder
    private var content: some View {
        if viewModel.viewState.isLoading {
            loadingView
        } else if let error = viewModel.viewState.errorMessage {
            errorView(error)
        } else if viewModel.viewState.showEmptyState {
            emptyStateView
        } else {
            collectionsList
        }
    }

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                GlassSectionHeader(Constants.featuredSection)

                CollectionCardSkeleton()
                    .padding(.horizontal, Spacing.md)

                GlassSectionHeader(Constants.myCollectionsSection)

                VStack(spacing: Spacing.sm) {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        UserCollectionRowSkeleton()
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Semantic.warning)

                Text(Constants.errorTitle)
                    .font(Typography.titleMedium)

                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.tap()
                    viewModel.handle(event: .onRefresh)
                } label: {
                    Text(Constants.tryAgain)
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.Accent.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .pressEffect()
            }
        }
        .padding(Spacing.lg)
    }

    private var emptyStateView: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(.secondary)

                Text(Constants.emptyTitle)
                    .font(Typography.titleMedium)

                Text(Constants.emptyMessage)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.tap()
                    viewModel.handle(event: .onCreateCollectionTapped)
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text(Constants.createNew)
                    }
                    .font(Typography.labelLarge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.Accent.primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .pressEffect()
            }
        }
        .padding(Spacing.lg)
    }

    private var collectionsList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if !viewModel.viewState.featuredCollections.isEmpty {
                    Section {
                        featuredCollectionsCarousel
                    } header: {
                        GlassSectionHeader(Constants.featuredSection)
                    }
                }

                Section {
                    if viewModel.viewState.showEmptyUserCollections {
                        emptyUserCollectionsView
                    } else {
                        userCollectionsList
                    }
                } header: {
                    HStack {
                        GlassSectionHeader(Constants.myCollectionsSection)
                        Spacer()
                        Button {
                            HapticManager.shared.tap()
                            viewModel.handle(event: .onCreateCollectionTapped)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: IconSize.lg))
                                .foregroundStyle(Color.Accent.primary)
                        }
                        .padding(.trailing, Spacing.md)
                    }
                }

                premiumSection
            }
        }
    }

    private var featuredCollectionsCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Spacing.md) {
                ForEach(viewModel.viewState.featuredCollections) { item in
                    CollectionCard(item: item) {
                        viewModel.handle(event: .onCollectionTapped(collectionId: item.id))
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
    }

    private var userCollectionsList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(viewModel.viewState.userCollections) { item in
                UserCollectionRow(item: item) {
                    viewModel.handle(event: .onCollectionTapped(collectionId: item.id))
                } onDelete: {
                    viewModel.handle(event: .onDeleteCollectionTapped(collectionId: item.id))
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    private var emptyUserCollectionsView: some View {
        GlassCard(style: .ultraThin, shadowStyle: .subtle, padding: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: IconSize.xl))
                    .foregroundStyle(.secondary)

                Text(Constants.emptyUserTitle)
                    .font(Typography.titleSmall)

                Text(Constants.emptyUserMessage)
                    .font(Typography.captionLarge)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
    }

    private var premiumSection: some View {
        GlassCard(style: .thick, shadowStyle: .medium, padding: Spacing.lg) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xl))
                    .foregroundStyle(Color.Accent.gold)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack {
                        Text(Constants.premiumSection)
                            .font(Typography.titleSmall)
                        PremiumBadge()
                    }
                    Text(Constants.premiumMessage)
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: IconSize.sm))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
    }
}

// MARK: - Skeleton Views

struct CollectionCardSkeleton: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    GlassCard(style: .thin, shadowStyle: .medium, padding: 0) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(Color.Semantic.skeleton)
                                .frame(width: 40, height: 40)

                            RoundedRectangle(cornerRadius: CornerRadius.xs)
                                .fill(Color.Semantic.skeleton)
                                .frame(height: 16)

                            RoundedRectangle(cornerRadius: CornerRadius.xs)
                                .fill(Color.Semantic.skeleton)
                                .frame(width: 100, height: 12)

                            RoundedRectangle(cornerRadius: CornerRadius.xs)
                                .fill(Color.Semantic.skeleton)
                                .frame(height: 4)
                        }
                        .padding(Spacing.md)
                    }
                    .frame(width: 180)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .shimmer()
    }
}

struct UserCollectionRowSkeleton: View {
    var body: some View {
        GlassCard(style: .ultraThin, shadowStyle: .subtle, padding: Spacing.md) {
            HStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.Semantic.skeleton)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.Semantic.skeleton)
                        .frame(width: 120, height: 14)

                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.Semantic.skeleton)
                        .frame(width: 80, height: 12)
                }

                Spacer()
            }
        }
        .shimmer()
    }
}

// MARK: - Premium Badge

struct PremiumBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: [Color.Accent.gold, Color.Accent.gold.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        CollectionsView(
            router: CollectionsNavigationRouter(),
            viewModel: CollectionsViewModel(serviceLocator: .preview)
        )
    }
}
