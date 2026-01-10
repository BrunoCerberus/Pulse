import SwiftUI

// MARK: - Constants

private enum Constants {
    static let title = String(localized: "summarization.title")
    static let subtitle = String(localized: "summarization.subtitle")
    static let generateButton = String(localized: "summarization.generate")
    static let cancelButton = String(localized: "summarization.cancel")
    static let retryButton = String(localized: "summarization.retry")
    static let loadingModel = String(localized: "summarization.loading_model")
    static let generating = String(localized: "summarization.generating")
    static let aiSummary = String(localized: "summarization.ai_summary")
}

// MARK: - Animation Constants

private enum AnimationConstants {
    static let stateTransition: Animation = .spring(response: 0.5, dampingFraction: 0.8)
    static let contentAppear: Animation = .easeOut(duration: 0.4)
    static let shimmerDuration: Double = 1.5
    static let pulseScale: CGFloat = 1.05
}

// MARK: - SummarizationSheet

struct SummarizationSheet: View {
    @ObservedObject var viewModel: ArticleDetailViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var headerAppeared = false
    @State private var contentAppeared = false

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
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                // Glow effect behind the icon
                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary.opacity(0.3))
                    .blur(radius: 20)

                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.gradient)
                    .symbolEffect(.bounce, options: reduceMotion ? .repeat(1) : .repeat(2))
            }

            Text(Constants.subtitle)
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Content Section

    @ViewBuilder
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

            Text("\(Int(progress * 100))%")
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

                Text(Constants.aiSummary)
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.Accent.primary)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: IconSize.sm))
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
    @State private var isHovered = false
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
        HStack(spacing: 4) {
            ForEach(0 ..< 3) { index in
                Circle()
                    .fill(Color.Accent.primary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animatingDot == index ? 1.3 : 0.8)
                    .opacity(animatingDot == index ? 1 : 0.5)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                animatingDot = (animatingDot + 1) % 3
            }
        }
    }
}

// MARK: - Formatted Summary Text

private struct FormattedSummaryText: View {
    let text: String
    let isGenerating: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ForEach(Array(formattedParagraphs.enumerated()), id: \.offset) { index, paragraph in
                if paragraph.isHeading {
                    Text(paragraph.text)
                        .font(Typography.labelLarge)
                        .foregroundStyle(.primary)
                        .padding(.top, index > 0 ? Spacing.sm : 0)
                } else if paragraph.isBullet {
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Circle()
                            .fill(Color.Accent.primary)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)

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
                // Cursor blink effect
                BlinkingCursor()
            }
        }
    }

    private var formattedParagraphs: [FormattedParagraph] {
        formatText(text)
    }

    private func formatText(_ text: String) -> [FormattedParagraph] {
        // Split by common separators and clean up
        let components = text
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "- ", with: "\n• ")
            .replacingOccurrences(of: "• ", with: "\n• ")
            .replacingOccurrences(of: ". ", with: ".\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return components.map { component in
            if component.hasPrefix("•") {
                return FormattedParagraph(
                    text: String(component.dropFirst()).trimmingCharacters(in: .whitespaces),
                    isHeading: false,
                    isBullet: true
                )
            } else if component.hasPrefix("**"), component.hasSuffix("**") {
                return FormattedParagraph(
                    text: String(component.dropFirst(2).dropLast(2)),
                    isHeading: true,
                    isBullet: false
                )
            } else if component.count < 50, component.hasSuffix(":") {
                return FormattedParagraph(
                    text: component,
                    isHeading: true,
                    isBullet: false
                )
            } else {
                return FormattedParagraph(
                    text: component,
                    isHeading: false,
                    isBullet: false
                )
            }
        }
    }
}

// MARK: - Formatted Paragraph Model

private struct FormattedParagraph {
    let text: String
    let isHeading: Bool
    let isBullet: Bool
}

// MARK: - Blinking Cursor

private struct BlinkingCursor: View {
    @State private var isVisible = true

    var body: some View {
        Rectangle()
            .fill(Color.Accent.primary)
            .frame(width: 2, height: 16)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}

#Preview {
    SummarizationSheet(
        viewModel: ArticleDetailViewModel(
            article: Article.mockArticles[0],
            serviceLocator: .preview
        )
    )
}
