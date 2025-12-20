import SwiftUI

// MARK: - Spacing

enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let pill: CGFloat = 999
}

// MARK: - Shadow Styles

enum ShadowStyle {
    case subtle
    case medium
    case elevated
    case floating

    var color: Color {
        Color.black.opacity(opacity)
    }

    var opacity: Double {
        switch self {
        case .subtle: return 0.05
        case .medium: return 0.1
        case .elevated: return 0.15
        case .floating: return 0.2
        }
    }

    var radius: CGFloat {
        switch self {
        case .subtle: return 4
        case .medium: return 8
        case .elevated: return 16
        case .floating: return 24
        }
    }

    var xOffset: CGFloat { 0 }

    var yOffset: CGFloat {
        switch self {
        case .subtle: return 2
        case .medium: return 4
        case .elevated: return 8
        case .floating: return 12
        }
    }
}

// MARK: - Glass Styles

enum GlassStyle {
    case ultraThin
    case thin
    case regular
    case thick

    var material: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        }
    }

    var borderOpacity: Double {
        switch self {
        case .ultraThin: return 0.15
        case .thin: return 0.2
        case .regular: return 0.25
        case .thick: return 0.3
        }
    }
}

// MARK: - Animation Timing

enum AnimationTiming {
    static let fast: Double = 0.15
    static let normal: Double = 0.25
    static let slow: Double = 0.4
    static let shimmer: Double = 1.5

    static var springBouncy: Animation {
        .spring(response: 0.4, dampingFraction: 0.6)
    }

    static var springSmooth: Animation {
        .spring(response: 0.35, dampingFraction: 0.8)
    }

    static var springQuick: Animation {
        .spring(response: 0.25, dampingFraction: 0.7)
    }
}

// MARK: - Icon Sizes

enum IconSize {
    static let xs: CGFloat = 12
    static let sm: CGFloat = 16
    static let md: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
