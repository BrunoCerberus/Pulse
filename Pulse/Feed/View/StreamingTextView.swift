import SwiftUI

// MARK: - StreamingTextView

struct StreamingTextView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(text)
                .font(Typography.bodyMedium)
                .foregroundStyle(.primary)
                .lineSpacing(4)

            BlinkingCursor()
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
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}

#Preview {
    StreamingTextView(text: "Today's reading covered a variety of topics including technology, business, and science...")
        .padding()
}
