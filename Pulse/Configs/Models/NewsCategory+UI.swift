import SwiftUI

extension NewsCategory {
    var color: Color {
        switch self {
        case .world: return .blue
        case .business: return .green
        case .technology: return .purple
        case .science: return .orange
        case .health: return .red
        case .sports: return .cyan
        case .entertainment: return .pink
        }
    }
}
