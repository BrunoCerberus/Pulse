// swiftlint:disable file_length
import EntropyCore
import SwiftUI

// MARK: - Constants

private enum Constants {
    static var title: String {
        AppLocalization.shared.localized("summarization.title")
    }

    static var subtitle: String {
        AppLocalization.shared.localized("summarization.subtitle")
    }

    static var generateButton: String {
        AppLocalization.shared.localized("summarization.generate")
    }

    static var cancelButton: String {
        AppLocalization.shared.localized("summarization.cancel")
    }

    static var retryButton: String {
        AppLocalization.shared.localized("summarization.retry")
    }

    static var loadingModel: String {
        AppLocalization.shared.localized("summarization.loading_model")
    }

    static var generating: String {
        AppLocalization.shared.localized("summarization.generating")
    }

    static var aiSummary: String {
        AppLocalization.shared.localized("summarization.ai_summary")
    }
}

// MARK: - Animation Constants

private enum AnimationConstants {
    static let stateTransition: Animation = .spring(response: 0.5, dampingFraction: 0.8)
    static let contentAppear: Animation = .easeOut(duration: 0.4)
    static let shimmerDuration: Double = 1.5
    static let iconGlowRadius: CGFloat = 20
    static let typingDotSize: CGFloat = 6
    static let typingDotSpacing: CGFloat = 4
    static let bulletPointSize: CGFloat = 6
    static let bulletPointTopPadding: CGFloat = 7
}

// MARK: - SummarizationSheet

struct SummarizationSheet: View {
    @StateObject var viewModel: SummarizationViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var headerAppeared = false
    @State private var contentAppeared = false

    init(viewModel: SummarizationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection
                        .opacity(headerAppeared ? 1 : 0)
                        .offset(y: headerAppeared ? 0 : -20)

                    contentSection
                        .opacity(contentAppeared ? 1 : 0)
                        .scaleEffect(contentAppeared ? 1 : 0.95)
                }
                .padding(Spacing.lg)
            }
            .background(Color.Glass.background)
            .navigationTitle(Constants.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(AnimationConstants.contentAppear.delay(0.1)) {
                headerAppeared = true
            }
            withAnimation(AnimationConstants.contentAppear.delay(0.25)) {
                contentAppeared = true
            }
        }
        .onDisappear {
            headerAppeared = false
            contentAppeared = false
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                // Glow effect behind the icon
                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary.opacity(0.3))
                    .blur(radius: AnimationConstants.iconGlowRadius)

                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.gradient)
                    .symbolEffect(.bounce, options: reduceMotion ? .repeat(1) : .repeat(2))
            }
            .accessibilityHidden(true)

            Text(Constants.subtitle)
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Content Section

    private var contentSection: some View {
        Group {
            switch viewModel.viewState.summarizationState {
            case .idle:
                idleContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
            case let .loadingModel(progress):
                loadingModelContent(progress: progress)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .generating:
                generatingContent
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            case .completed:
                completedContent
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)).combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
            case let .error(message):
                errorContent(message: message)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(AnimationConstants.stateTransition, value: viewModel.viewState.summarizationState)
    }

    // MARK: - Idle State

    private var idleContent: some View {
        VStack(spacing: Spacing.lg) {
            articlePreview

            GenerateButton {
                HapticManager.shared.buttonPress()
                viewModel.handle(event: .onSummarizationStarted)
            }
        }
    }

    private var articlePreview: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(viewModel.viewState.article.title)
                .font(Typography.headlineSmall)
                .lineLimit(3)

            HStack(spacing: Spacing.xs) {
                Text(viewModel.viewState.article.source.name)
                Circle()
                    .fill(.secondary)
                    .frame(width: 3, height: 3)
                Text(viewModel.viewState.article.formattedDate)
            }
            .font(Typography.captionLarge)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg)
    }

    // MARK: - Loading Model State

    private func loadingModelContent(progress: Double) -> some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 8)

                // Progress fill with gradient
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.Accent.gradient)
                        .frame(width: geometry.size.width * progress)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
                .frame(height: 8)
            }
            .frame(height: 8)

            HStack(spacing: Spacing.sm) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Color.Accent.primary)

                Text(Constants.loadingModel)
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
            }

            Text("\(Int((progress * 100).rounded()))%")
                .font(Typography.headlineSmall)
                .foregroundStyle(Color.Accent.primary)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: progress)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassBackground(style: .regular, cornerRadius: CornerRadius.lg)
    }

    // MARK: - Generating State

    private var generatingContent: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                TypingIndicator()

                Text(Constants.generating)
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.viewState.generatedSummary.isEmpty {
                FormattedSummaryText(text: viewModel.viewState.generatedSummary, isGenerating: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .glassBackground(style: .thin, cornerRadius: CornerRadius.md)
            }

            Button {
                HapticManager.shared.tap()
                viewModel.handle(event: .onSummarizationCancelled)
            } label: {
                Text(Constants.cancelButton)
                    .font(Typography.labelMedium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .pressEffect()
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassBackground(style: .regular, cornerRadius: CornerRadius.lg)
    }

    // MARK: - Completed State

    private var completedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.Accent.primary)
                    .symbolEffect(.pulse.byLayer, options: .repeat(.periodic(delay: 2.0)))
                    .accessibilityHidden(true)

                Text(Constants.aiSummary)
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.Accent.primary)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: IconSize.sm))
                    .accessibilityHidden(true)
            }

            Divider()
                .background(Color.Accent.primary.opacity(0.3))

            FormattedSummaryText(text: viewModel.viewState.generatedSummary, isGenerating: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .stroke(Color.Accent.primary.opacity(0.2), lineWidth: 1)
        )
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg)
    }

    // MARK: - Error State

    private func errorContent(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: IconSize.xxl + Spacing.lg, height: IconSize.xxl + Spacing.lg)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: IconSize.xl))
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, options: .repeat(1))
            }
            .accessibilityHidden(true)

            Text(message)
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)

            Button {
                HapticManager.shared.tap()
                viewModel.handle(event: .onSummarizationStarted)
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text(Constants.retryButton)
                }
                .font(Typography.labelMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(Color.Accent.gradient)
                .clipShape(Capsule())
            }
            .pressEffect()
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassBackground(style: .regular, cornerRadius: CornerRadius.lg)
    }
}

// MARK: - Generate Button Component

private struct GenerateButton: View {
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .symbolEffect(.variableColor.iterative, options: reduceMotion ? .repeat(1) : .repeat(.continuous))

                Text(Constants.generateButton)
            }
            .font(Typography.labelLarge)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(
                ZStack {
                    Color.Accent.gradient

                    // Shimmer effect
                    if !reduceMotion {
                        ShimmerOverlay()
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
            .shadow(color: Color.Accent.primary.opacity(0.3), radius: 8, y: 4)
        }
        .pressEffect()
    }
}

// MARK: - Shimmer Overlay

private struct ShimmerOverlay: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    .clear,
                    .white.opacity(0.2),
                    .clear,
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 0.5)
            .offset(x: -geometry.size.width * 0.5 + phase * geometry.size.width * 1.5)
            .onAppear {
                withAnimation(
                    .linear(duration: AnimationConstants.shimmerDuration)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
        }
        .clipped()
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var animatingDot = 0

    var body: some View {
        HStack(spacing: AnimationConstants.typingDotSpacing) {
            ForEach(0 ..< 3) { index in
                Circle()
                    .fill(Color.Accent.primary)
                    .frame(width: AnimationConstants.typingDotSize, height: AnimationConstants.typingDotSize)
                    .scaleEffect(animatingDot == index ? 1.3 : 0.8)
                    .opacity(animatingDot == index ? 1 : 0.5)
            }
        }
        .accessibilityHidden(true)
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .milliseconds(300))
                    withAnimation(.easeInOut(duration: 0.2)) {
                        animatingDot = (animatingDot + 1) % 3
                    }
                } catch {
                    break
                }
            }
        }
    }
}

// MARK: - Formatted Summary Text

private struct FormattedSummaryText: View {
    let text: String
    let isGenerating: Bool

    @State private var cachedParagraphs: [FormattedParagraph] = []

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(Array(cachedParagraphs.enumerated()), id: \.element.id) { index, paragraph in
                if paragraph.isHeading {
                    Text(paragraph.text)
                        .font(Typography.labelLarge)
                        .foregroundStyle(.primary)
                        .padding(.top, index > 0 ? Spacing.sm : 0)
                } else if paragraph.isBullet {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Circle()
                            .fill(Color.Accent.primary)
                            .frame(
                                width: AnimationConstants.bulletPointSize,
                                height: AnimationConstants.bulletPointSize
                            )
                            .padding(.top, AnimationConstants.bulletPointTopPadding)

                        Text(paragraph.text)
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                    }
                } else {
                    Text(paragraph.text)
                        .font(Typography.bodyMedium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                }
            }

            if isGenerating {
                BlinkingCursor()
            }
        }
        .onAppear {
            cachedParagraphs = SummarizationTextFormatter.format(text)
        }
        .onChange(of: text) { _, newValue in
            cachedParagraphs = SummarizationTextFormatter.format(newValue)
        }
    }
}

// MARK: - Blinking Cursor

private struct BlinkingCursor: View {
    @State private var isVisible = true

    var body: some View {
        Rectangle()
            .fill(Color.Accent.primary)
            .frame(width: 2, height: 16)
            .opacity(isVisible ? 1 : 0)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}

#Preview {
    SummarizationSheet(
        viewModel: SummarizationViewModel(
            article: Article.mockArticles[0],
            serviceLocator: .preview
        )
    )
    .preferredColorScheme(.dark)
}
