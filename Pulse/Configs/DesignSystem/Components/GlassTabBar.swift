import EntropyCore
import SwiftUI

// MARK: - Glass Tab Item

struct GlassTabItem: Identifiable {
    let id: AppTab
    let title: String
    let icon: String
    let selectedIcon: String

    static var items: [GlassTabItem] {
        let loc = AppLocalization.shared
        return [
            GlassTabItem(
                id: .home, title: loc.localized("tab.home"),
                icon: "newspaper", selectedIcon: "newspaper.fill"
            ),
            GlassTabItem(
                id: .feed, title: loc.localized("tab.feed"),
                icon: "text.document", selectedIcon: "text.document.fill"
            ),
            GlassTabItem(
                id: .bookmarks, title: loc.localized("tab.bookmarks"),
                icon: "bookmark", selectedIcon: "bookmark.fill"
            ),
            GlassTabItem(
                id: .search, title: loc.localized("tab.search"),
                icon: "magnifyingglass", selectedIcon: "magnifyingglass"
            ),
        ]
    }
}

// MARK: - Glass Tab Bar

struct GlassTabBar: View {
    @Binding var selectedTab: AppTab
    var items: [GlassTabItem] = GlassTabItem.items

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var tabAnimation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                tabButton(for: item)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.Border.adaptive(for: colorScheme), lineWidth: 0.5)
        )
        .depthShadow(.floating)
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.xs)
    }

    private func tabButton(for item: GlassTabItem) -> some View {
        let isSelected = selectedTab == item.id

        return Button {
            if reduceMotion {
                selectedTab = item.id
            } else {
                withAnimation(AnimationTiming.springSmooth) {
                    selectedTab = item.id
                }
            }
            HapticManager.shared.tabChange()
        } label: {
            VStack(spacing: Spacing.xxs) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.Accent.primary.opacity(0.15))
                            .frame(width: 48, height: 32)
                            .matchedGeometryEffect(id: "tabIndicator", in: tabAnimation)
                    }

                    Image(systemName: isSelected ? item.selectedIcon : item.icon)
                        .font(.system(size: IconSize.md))
                        .symbolEffect(.bounce, value: isSelected)
                        .foregroundStyle(isSelected ? Color.Accent.primary : .secondary)
                }

                Text(item.title)
                    .font(Typography.captionSmall)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityHint(String(format: AppLocalization.shared.localized("tab.switch_hint"), item.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Tab Bar Modifier

struct GlassTabBarModifier: ViewModifier {
    @Binding var selectedTab: AppTab

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                GlassTabBar(selectedTab: $selectedTab)
            }
    }
}

extension View {
    func glassTabBar(selectedTab: Binding<AppTab>) -> some View {
        modifier(GlassTabBarModifier(selectedTab: selectedTab))
    }
}

// MARK: - Previews

#Preview("Glass Tab Bar") {
    struct PreviewWrapper: View {
        @State private var selectedTab: AppTab = .home

        var body: some View {
            ZStack {
                LinearGradient.meshFallback
                    .ignoresSafeArea()

                VStack {
                    Text("Selected: \(String(describing: selectedTab))")
                        .font(Typography.titleMedium)

                    Spacer()
                }
                .padding(.top, 100)
            }
            .glassTabBar(selectedTab: $selectedTab)
        }
    }

    return PreviewWrapper()
        .preferredColorScheme(.dark)
}
