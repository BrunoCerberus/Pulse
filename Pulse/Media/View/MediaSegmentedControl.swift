import EntropyCore
import SwiftUI

/// Segmented control for filtering media by type (All/Videos/Podcasts).
///
/// Features:
/// - Chip-style toggles with animated selection
/// - Matched geometry effect for smooth transitions
/// - Glow effect on selected state
/// - Respects media type colors
/// - Haptic feedback on selection
struct MediaSegmentedControl: View {
    let selectedType: MediaType?
    let onSelect: (MediaType?) -> Void

    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme

    /// Options for the segmented control (nil = All, then each MediaType).
    private let options: [MediaType?] = [nil] + MediaType.allCases

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(options, id: \.self) { type in
                MediaTypeChip(
                    type: type,
                    isSelected: selectedType == type,
                    namespace: animation
                ) {
                    HapticManager.shared.selectionChanged()
                    withAnimation(AnimationTiming.springSmooth) {
                        onSelect(type)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Media Type Chip

private struct MediaTypeChip: View {
    let type: MediaType?
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    private var chipColor: Color {
        type?.color ?? Color.Accent.primary
    }

    private var label: String {
        type?.displayName ?? String(localized: "media.all_types", defaultValue: "All")
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                if let type {
                    Image(systemName: type.icon)
                        .font(.system(size: IconSize.sm))
                        .symbolEffect(.bounce, value: isSelected)
                }

                Text(label)
                    .font(Typography.labelMedium)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundStyle(isSelected ? .white : chipColor)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background {
                if isSelected {
                    Capsule()
                        .fill(chipColor.gradient)
                        .matchedGeometryEffect(id: "selection", in: namespace)
                } else {
                    Capsule()
                        .fill(chipColor.opacity(0.12))
                        .overlay(
                            Capsule()
                                .stroke(chipColor.opacity(0.25), lineWidth: 0.5)
                        )
                }
            }
            .glowEffect(color: isSelected ? chipColor : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .pressEffect(scale: 0.95)
    }
}

// MARK: - Preview

#Preview("Media Segmented Control") {
    struct PreviewWrapper: View {
        @State private var selectedType: MediaType?

        var body: some View {
            ZStack {
                LinearGradient.meshFallback
                    .ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    MediaSegmentedControl(
                        selectedType: selectedType,
                        onSelect: { selectedType = $0 }
                    )

                    Text("Selected: \(selectedType?.displayName ?? "All")")
                        .foregroundStyle(.secondary)

                    // Show each state
                    VStack(spacing: Spacing.md) {
                        Text("Individual States")
                            .font(Typography.captionMedium)
                            .foregroundStyle(.secondary)

                        HStack(spacing: Spacing.sm) {
                            MediaSegmentedControl(
                                selectedType: nil,
                                onSelect: { _ in }
                            )
                        }

                        HStack(spacing: Spacing.sm) {
                            MediaSegmentedControl(
                                selectedType: .video,
                                onSelect: { _ in }
                            )
                        }

                        HStack(spacing: Spacing.sm) {
                            MediaSegmentedControl(
                                selectedType: .podcast,
                                onSelect: { _ in }
                            )
                        }
                    }
                    .padding(.top, Spacing.xl)
                }
            }
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
