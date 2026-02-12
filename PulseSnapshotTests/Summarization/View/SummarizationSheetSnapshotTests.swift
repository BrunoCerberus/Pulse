import EntropyCore
@testable import Pulse
import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SummarizationSheetSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    // MARK: - Idle State

    func testSummarizationSheetIdleState() {
        let view = SummarizationIdlePreview()
            .frame(width: 393, height: 500)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }

    // MARK: - Loading Model State

    func testSummarizationSheetLoadingModelState() {
        let view = SummarizationLoadingPreview()
            .frame(width: 393, height: 500)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }

    // MARK: - Generating State

    func testSummarizationSheetGeneratingState() {
        let view = SummarizationGeneratingPreview()
            .frame(width: 393, height: 500)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }

    // MARK: - Completed State

    func testSummarizationSheetCompletedState() {
        let view = SummarizationCompletedPreview()
            .frame(width: 393, height: 600)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }

    // MARK: - Error State

    func testSummarizationSheetErrorState() {
        let view = SummarizationErrorPreview()
            .frame(width: 393, height: 500)

        let controller = UIHostingController(rootView: view)

        assertSnapshot(
            of: controller,
            as: SnapshotConfig.snapshotting(on: SnapshotConfig.iPhoneAir),
            record: false
        )
    }
}

// MARK: - Preview Helpers

private struct SummarizationIdlePreview: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection
                    idleContent
                }
                .padding(Spacing.lg)
            }
            .background(Color.Glass.background)
            .navigationTitle("AI Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary.opacity(0.3))
                    .blur(radius: 20)

                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.gradient)
            }

            Text("Let AI summarize this article for you")
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var idleContent: some View {
        VStack(spacing: Spacing.lg) {
            // Article preview card
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("SwiftUI 6.0 Brings Revolutionary New Features")
                    .font(Typography.labelLarge)
                    .lineLimit(2)

                Text("Apple announces major updates to SwiftUI at WWDC 2024 with new animation APIs.")
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: Spacing.xs) {
                    Image(systemName: "newspaper.fill")
                        .font(.caption)
                    Text("TechCrunch")
                        .font(Typography.captionLarge)
                }
                .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .glassBackground(style: .thin, cornerRadius: CornerRadius.md)

            // Generate button
            Button {} label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                    Text("Generate Summary")
                }
                .font(Typography.labelLarge)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.Accent.gradient)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                .shadow(color: Color.Accent.primary.opacity(0.3), radius: 8, y: 4)
            }
        }
    }
}

private struct SummarizationLoadingPreview: View {
    private let progress: Double = 0.45

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection
                    loadingContent
                }
                .padding(Spacing.lg)
            }
            .background(Color.Glass.background)
            .navigationTitle("AI Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary.opacity(0.3))
                    .blur(radius: 20)

                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.gradient)
            }

            Text("Let AI summarize this article for you")
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var loadingContent: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 8)

                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(Color.Accent.gradient)
                        .frame(width: geometry.size.width * progress)
                }
                .frame(height: 8)
            }
            .frame(height: 8)

            HStack(spacing: Spacing.sm) {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Color.Accent.primary)

                Text("Loading AI model...")
                    .font(Typography.bodySmall)
                    .foregroundStyle(.secondary)
            }

            Text("\(Int((progress * 100).rounded()))%")
                .font(Typography.headlineSmall)
                .foregroundStyle(Color.Accent.primary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassBackground(style: .regular, cornerRadius: CornerRadius.lg)
    }
}

private struct SummarizationGeneratingPreview: View {
    private let generatedText = "This article discusses the latest updates to SwiftUI, including new animation APIs and improved performance."

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection
                    generatingContent
                }
                .padding(Spacing.lg)
            }
            .background(Color.Glass.background)
            .navigationTitle("AI Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary.opacity(0.3))
                    .blur(radius: 20)

                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.gradient)
            }

            Text("Let AI summarize this article for you")
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var generatingContent: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                HStack(spacing: 4) {
                    ForEach(0 ..< 3, id: \.self) { index in
                        Circle()
                            .fill(Color.Accent.primary)
                            .frame(width: 6, height: 6)
                            .opacity(index == 1 ? 1 : 0.5)
                            .scaleEffect(index == 1 ? 1.3 : 0.8)
                    }
                }

                Text("Generating summary...")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.secondary)
            }

            Text(generatedText)
                .font(Typography.bodyMedium)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .glassBackground(style: .thin, cornerRadius: CornerRadius.md)

            Button {} label: {
                Text("Cancel")
                    .font(Typography.labelMedium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg)
    }
}

private struct SummarizationCompletedPreview: View {
    private let summary = """
    **Key Points**
    This article covers the major SwiftUI updates announced at WWDC.
    Main Features:
    - New animation system with spring physics
    - Improved performance for complex views
    - Better accessibility support
    """

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection
                    completedContent
                }
                .padding(Spacing.lg)
            }
            .background(Color.Glass.background)
            .navigationTitle("AI Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary.opacity(0.3))
                    .blur(radius: 20)

                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.gradient)
            }

            Text("Let AI summarize this article for you")
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var completedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.Accent.primary)

                Text("AI Summary")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.Accent.primary)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: IconSize.sm))
            }

            Divider()
                .background(Color.Accent.primary.opacity(0.3))

            // Formatted summary content
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Key Points")
                    .font(Typography.labelLarge)
                    .foregroundStyle(.primary)

                Text("This article covers the major SwiftUI updates announced at WWDC.")
                    .font(Typography.bodyMedium)
                    .foregroundStyle(.primary)
                    .lineSpacing(4)

                Text("Main Features:")
                    .font(Typography.labelLarge)
                    .foregroundStyle(.primary)
                    .padding(.top, Spacing.sm)

                ForEach(["New animation system with spring physics", "Improved performance for complex views", "Better accessibility support"], id: \.self) { item in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Circle()
                            .fill(Color.Accent.primary)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)

                        Text(item)
                            .font(Typography.bodyMedium)
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .stroke(Color.Accent.primary.opacity(0.2), lineWidth: 1)
        )
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg)
    }
}

private struct SummarizationErrorPreview: View {
    private let errorMessage = "Failed to generate summary. The model could not process the content."

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerSection
                    errorContent
                }
                .padding(Spacing.lg)
            }
            .background(Color.Glass.background)
            .navigationTitle("AI Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.primary.opacity(0.3))
                    .blur(radius: 20)

                Image(systemName: "sparkles")
                    .font(.system(size: IconSize.xxl))
                    .foregroundStyle(Color.Accent.gradient)
            }

            Text("Let AI summarize this article for you")
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var errorContent: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: IconSize.xxl + Spacing.lg, height: IconSize.xxl + Spacing.lg)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: IconSize.xl))
                    .foregroundStyle(.orange)
            }

            Text(errorMessage)
                .font(Typography.bodySmall)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)

            Button {} label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(Typography.labelMedium)
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(Color.Accent.gradient)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .glassBackground(style: .thin, cornerRadius: CornerRadius.lg)
    }
}
