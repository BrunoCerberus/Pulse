import SwiftUI

// MARK: - Glass Colors

extension Color {
    enum Glass {
        static let background = Color(.systemBackground).opacity(0.7)
        static let surface = Color(.secondarySystemBackground).opacity(0.6)
        static let elevated = Color(.tertiarySystemBackground).opacity(0.8)
        static let overlay = Color.black.opacity(0.3)
    }

    enum Border {
        static var glass: Color {
            Color.white.opacity(0.2)
        }

        static var glassDark: Color {
            Color.black.opacity(0.1)
        }

        static var glassSubtle: Color {
            Color.white.opacity(0.1)
        }

        static func adaptive(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? glass : glassDark
        }
    }

    enum Accent {
        static let primary = Color.blue
        static let secondary = Color.purple
        static let tertiary = Color.cyan

        static var gradient: LinearGradient {
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var vibrantGradient: LinearGradient {
            LinearGradient(
                colors: [.cyan, .blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static var warmGradient: LinearGradient {
            LinearGradient(
                colors: [.orange, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    enum Semantic {
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
    }
}

// MARK: - Mesh Gradient Backgrounds

@available(iOS 18.0, *)
extension MeshGradient {
    static var glassMesh: MeshGradient {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .blue.opacity(0.3), .purple.opacity(0.2), .cyan.opacity(0.3),
                .purple.opacity(0.2), .blue.opacity(0.1), .purple.opacity(0.2),
                .cyan.opacity(0.3), .purple.opacity(0.2), .blue.opacity(0.3),
            ]
        )
    }

    static var warmMesh: MeshGradient {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: [
                .orange.opacity(0.3), .pink.opacity(0.2), .red.opacity(0.3),
                .pink.opacity(0.2), .orange.opacity(0.1), .pink.opacity(0.2),
                .red.opacity(0.3), .pink.opacity(0.2), .orange.opacity(0.3),
            ]
        )
    }
}

// MARK: - Gradient Backgrounds (Fallback for iOS < 18)

extension LinearGradient {
    static var meshFallback: LinearGradient {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.15),
                Color.purple.opacity(0.1),
                Color.cyan.opacity(0.15),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var subtleBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemGray6).opacity(0.5),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var cardOverlay: LinearGradient {
        LinearGradient(
            colors: [.clear, .black.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var heroOverlay: LinearGradient {
        LinearGradient(
            colors: [
                .clear,
                .black.opacity(0.3),
                .black.opacity(0.7),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
