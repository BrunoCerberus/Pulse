import EntropyCore
import SwiftUI

// MARK: - StreamingTextView

struct StreamingTextView: View {
    let text: String

    @ScaledMetric(relativeTo: .largeTitle) private var dropCapWidth: CGFloat = 44

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left accent border (matching DigestCard style)
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Color.Accent.primary, Color.Accent.primary.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3)
                .padding(.trailing, Spacing.md)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                streamingContent

                BlinkingCursor()
            }
        }
    }

    // MARK: - Streaming Content with Drop Cap

    @ViewBuilder
    private var streamingContent: some View {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedText.isEmpty {
            // Show placeholder while waiting for first character
            Text(" ")
                .font(Typography.aiContentMedium)
        } else {
            let firstChar = String(trimmedText.prefix(1))
            let remainingText = String(trimmedText.dropFirst())

            HStack(alignment: .top, spacing: 0) {
                // Drop cap
                Text(firstChar)
                    .font(Typography.aiDropCap)
                    .foregroundStyle(Color.Accent.primary)
                    .frame(width: dropCapWidth, alignment: .leading)
                    .padding(.trailing, Spacing.xs)

                // Remaining text
                Text(remainingText)
                    .font(Typography.aiContentMedium)
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Blinking Cursor

private struct BlinkingCursor: View {
    @State private var isVisible = true
    @ScaledMetric(relativeTo: .body) private var cursorHeight: CGFloat = 16

    var body: some View {
        Rectangle()
            .fill(Color.Accent.primary)
            .frame(width: 2, height: cursorHeight)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}

#Preview {
    StreamingTextView(
        text: "Today's reading covered a variety of topics including technology, business, and science..."
    )
    .padding()
    .preferredColorScheme(.dark)
}
