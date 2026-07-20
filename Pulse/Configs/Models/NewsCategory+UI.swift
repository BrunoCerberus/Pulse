import SwiftUI

extension NewsCategory {
    var color: Color {
        switch self {
        case .world: .blue
        case .business: .green
        case .technology: .purple
        case .science: .orange
        case .health: .red
        case .sports: .cyan
        case .entertainment: .pink
        }
    }
}
