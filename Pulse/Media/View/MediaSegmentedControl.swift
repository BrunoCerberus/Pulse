import SwiftUI

/// Segmented control for filtering media by type (All/Videos/Podcasts).
///
/// Features:
/// - Pill-style toggle with animated selection
/// - Shows icons and labels for each type
/// - Respects media type colors
/// - Glass morphism background
struct MediaSegmentedControl: View {
    let selectedType: MediaType?
    let onSelect: (MediaType?) -> Void

    /// Options for the segmented control (nil = All, then each MediaType).
    private let options: [MediaType?] = [nil] + MediaType.allCases

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(options, id: \.self) { type in
                segmentButton(for: type)
            }
        }
        .padding(Spacing.xxs)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
        }
    }

    private func segmentButton(for type: MediaType?) -> some View {
        let isSelected = selectedType == type

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                onSelect(type)
            }
        } label: {
            HStack(spacing: Spacing.xxs) {
                if let type {
                    Image(systemName: type.icon)
                        .font(.system(size: IconSize.xs))
                }
                Text(type?.displayName ?? String(localized: "media.all_types", defaultValue: "All"))
                    .font(Typography.labelMedium)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background {
                if isSelected {
                    Capsule()
                        .fill(type?.color ?? Color.Accent.primary)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: selectedType)
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
                }
            }
        }
    }

    return PreviewWrapper()
}
