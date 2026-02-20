import EntropyCore
import SwiftUI

/// A compact banner that appears when the device has no network connectivity.
///
/// Displays a `wifi.slash` icon and "You're offline" text with a warning-style background.
/// Designed to be placed at the top of the screen in a VStack above the main content.
struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "wifi.slash")
                .font(.system(size: IconSize.sm, weight: .semibold))

            Text(String(localized: "offline.banner"))
                .font(Typography.labelMedium)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
        .background(Color.orange)
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "offline.banner"))
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    VStack(spacing: 0) {
        OfflineBannerView()
        Spacer()
    }
    .preferredColorScheme(.dark)
}
