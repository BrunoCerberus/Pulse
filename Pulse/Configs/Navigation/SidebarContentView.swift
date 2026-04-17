import SwiftUI

/// Sidebar list shown on regular width (iPad / Mac Catalyst) as the leading
/// column of `NavigationSplitView`. Renders one row per `AppTab`, bound to the
/// same `selectedTab` that drives the compact `TabView`.
struct SidebarContentView: View {
    @Binding var selectedTab: AppTab
    @ObservedObject private var appLocalization = AppLocalization.shared

    private var optionalSelection: Binding<AppTab?> {
        Binding<AppTab?>(
            get: { selectedTab },
            set: { newValue in
                if let newValue {
                    selectedTab = newValue
                }
            }
        )
    }

    var body: some View {
        List(selection: optionalSelection) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Label(tab.title, systemImage: tab.symbolImage)
                    .tag(tab)
            }
        }
        .navigationTitle("Pulse")
    }
}

#Preview {
    NavigationSplitView {
        SidebarContentView(selectedTab: .constant(.home))
    } detail: {
        Text("Detail")
    }
}
