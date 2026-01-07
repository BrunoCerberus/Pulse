import SwiftUI

// MARK: - Digest Constants

enum DigestConstants {
    static let title = String(localized: "digest.title")
    static let subtitle = String(localized: "digest.subtitle")
    static let selectSource = String(localized: "digest.select_source")
    static let generate = String(localized: "digest.generate")
    static let generating = String(localized: "digest.generating")
    static let cancel = String(localized: "common.cancel")
    static let clear = String(localized: "digest.clear")
    static let newDigest = String(localized: "digest.new")
    static let share = String(localized: "common.share")
    static let retry = String(localized: "common.try_again")
    static let modelLoading = String(localized: "digest.model_loading")
    static let modelReady = String(localized: "digest.model_ready")
    static let noArticles = String(localized: "digest.no_articles")
    static let configureTopics = String(localized: "digest.configure_topics")
    static let noTopicsTitle = String(localized: "digest.no_topics.title")
    static let noTopicsMessage = String(localized: "digest.no_topics.message")
    static let articlesAvailable = String(localized: "digest.articles_available")
    static let moreArticles = String(localized: "digest.more_articles")
    static let error = String(localized: "common.error")
    static let fromArticles = String(localized: "digest.from_articles")
}

// MARK: - Model Status Indicator

struct DigestModelStatusIndicator: View {
    let modelStatus: DigestModelStatus

    var body: some View {
        Group {
            switch modelStatus {
            case .notLoaded, .loading:
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .tint(.secondary)
                    Text(DigestConstants.modelLoading)
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.md)
            case .ready:
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.Semantic.success)
                    Text(DigestConstants.modelReady)
                        .font(Typography.captionLarge)
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.md)
            case let .error(message):
                Text(message)
                    .font(Typography.captionLarge)
                    .foregroundStyle(Color.Semantic.warning)
                    .padding(Spacing.md)
            }
        }
    }
}

// MARK: - Model Loading Bar

struct DigestModelLoadingBar: View {
    let progress: Double

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ProgressView(value: progress)
                .tint(Color.Accent.primary)
            Text("\(DigestConstants.modelLoading) \(Int(progress * 100))%")
                .font(Typography.captionLarge)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Loading View

struct DigestLoadingView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text(String(localized: "digest.loading_articles"))
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .containerRelativeFrame(.vertical) { height, _ in
            height * 0.5
        }
    }
}

// MARK: - Error View

struct DigestErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Semantic.warning)

                Text(DigestConstants.error)
                    .font(Typography.titleMedium)

                Text(message)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.tap()
                    onRetry()
                } label: {
                    Text(DigestConstants.retry)
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
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Empty State View

struct DigestEmptyStateView: View {
    var body: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(.secondary)

                Text(DigestConstants.noArticles)
                    .font(Typography.titleMedium)

                Text(String(localized: "digest.empty.message"))
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - No Topics View

struct DigestNoTopicsView: View {
    let onConfigureTopics: () -> Void

    var body: some View {
        GlassCard(style: .thin, shadowStyle: .medium, padding: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary)

                Text(DigestConstants.noTopicsTitle)
                    .font(Typography.titleMedium)

                Text(DigestConstants.noTopicsMessage)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.shared.buttonPress()
                    onConfigureTopics()
                } label: {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text(DigestConstants.configureTopics)
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
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Generate Button

struct DigestGenerateButton: View {
    let canGenerate: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.buttonPress()
            onTap()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                Text(DigestConstants.generate)
            }
            .font(Typography.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                canGenerate
                    ? Color.Accent.gradient
                    : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canGenerate)
        .pressEffect()
        .accessibilityIdentifier("generateDigestButton")
    }
}

// MARK: - Generating View

struct DigestGeneratingView: View {
    let generationProgress: String
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                ForEach(0 ..< 3, id: \.self) { _ in
                    Image(systemName: "sparkle")
                        .font(.system(size: IconSize.xl))
                        .foregroundStyle(Color.Accent.primary)
                        .offset(
                            x: CGFloat.random(in: -30 ... 30),
                            y: CGFloat.random(in: -30 ... 30)
                        )
                        .opacity(0.6)
                }

                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary)
                    .symbolEffect(.pulse)
            }

            Text(DigestConstants.generating)
                .font(Typography.titleMedium)

            if !generationProgress.isEmpty {
                GlassCard(style: .thin, padding: Spacing.md) {
                    Text(generationProgress)
                        .font(Typography.bodyMedium)
                        .lineLimit(10)
                }
                .padding(.horizontal, Spacing.lg)
            }

            Button {
                HapticManager.shared.tap()
                onCancel()
            } label: {
                Text(DigestConstants.cancel)
                    .font(Typography.labelLarge)
                    .foregroundStyle(Color.Semantic.warning)
            }

            Spacer()
        }
        .accessibilityIdentifier("digestGeneratingView")
    }
}

// MARK: - Result View

struct DigestResultView: View {
    let digest: DigestResult
    let onClear: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                GlassCard(style: .regular, padding: Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(DigestConstants.title)
                                .font(Typography.titleSmall)
                            Text("\(DigestConstants.fromArticles) \(digest.articleCount)")
                                .font(Typography.captionLarge)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(digest.generatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(Typography.captionLarge)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, Spacing.lg)

                GlassCard(style: .thin, padding: Spacing.lg) {
                    Text(digest.content)
                        .font(Typography.bodyMedium)
                }
                .padding(.horizontal, Spacing.lg)

                HStack(spacing: Spacing.md) {
                    Button {
                        HapticManager.shared.tap()
                        onClear()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text(DigestConstants.newDigest)
                        }
                        .font(Typography.labelLarge)
                        .foregroundStyle(Color.Accent.primary)
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.md)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }

                    ShareLink(item: digest.content) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text(DigestConstants.share)
                        }
                        .font(Typography.labelLarge)
                        .foregroundStyle(.white)
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.md)
                        .background(Color.Accent.primary)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.lg)
        }
        .accessibilityIdentifier("digestResultView")
    }
}
