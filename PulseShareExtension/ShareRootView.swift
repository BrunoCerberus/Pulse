import SwiftUI
import UIKit

/// SwiftUI surface presented by the Pulse Share Extension.
///
/// Renders a lightweight preview of the URL the user is sharing and offers
/// a primary action that enqueues the URL for the main app to summarize on
/// device, plus a cancel action that dismisses the extension. The view is
/// intentionally free of design-system imports — the extension target does
/// not link `EntropyCore` to keep its memory footprint small.
struct ShareRootView: View {
    let url: URL
    let onSummarize: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            header
            urlPreview
            actionButtons
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text("Save to Pulse")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
        }
    }

    private var urlPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(url.host ?? url.absoluteString)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(url.absoluteString)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shared link from \(url.host ?? "the web"). \(url.absoluteString)")
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: onSummarize) {
                Label("Summarize with AI in Pulse", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Sends this article to Pulse for on-device summarization.")

            Button("Cancel", role: .cancel, action: onCancel)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
#Preview {
    ShareRootView(
        url: URL(string: "https://www.theguardian.com/technology/2026/apr/08/example-article")!,
        onSummarize: {},
        onCancel: {}
    )
}
#endif
