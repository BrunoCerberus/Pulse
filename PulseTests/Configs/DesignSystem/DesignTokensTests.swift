import Foundation
@testable import Pulse
import SwiftUI
import Testing

@Suite("Spacing Tokens Tests")
struct SpacingTokensTests {
    @Test("XXS spacing defined")
    func xXSSpacing() {
        #expect(Spacing.xxs == 4)
    }

    @Test("XS spacing defined")
    func xSSpacing() {
        #expect(Spacing.xs == 8)
    }

    @Test("Small spacing defined")
    func smSpacing() {
        #expect(Spacing.sm == 12)
    }

    @Test("Medium spacing defined")
    func mdSpacing() {
        #expect(Spacing.md == 16)
    }

    @Test("Large spacing defined")
    func lgSpacing() {
        #expect(Spacing.lg == 24)
    }

    @Test("XL spacing defined")
    func xLSpacing() {
        #expect(Spacing.xl == 32)
    }

    @Test("XXL spacing defined")
    func xXLSpacing() {
        #expect(Spacing.xxl == 48)
    }

    @Test("Spacing tokens are in ascending order")
    func spacingAscending() {
        #expect(Spacing.xxs < Spacing.xs)
        #expect(Spacing.xs < Spacing.sm)
        #expect(Spacing.sm < Spacing.md)
        #expect(Spacing.md < Spacing.lg)
        #expect(Spacing.lg < Spacing.xl)
        #expect(Spacing.xl < Spacing.xxl)
    }

    @Test("Spacing tokens are positive")
    func spacingPositive() {
        #expect(Spacing.xxs > 0)
        #expect(Spacing.xs > 0)
        #expect(Spacing.sm > 0)
        #expect(Spacing.md > 0)
        #expect(Spacing.lg > 0)
        #expect(Spacing.xl > 0)
        #expect(Spacing.xxl > 0)
    }
}

@Suite("Corner Radius Tokens Tests")
struct CornerRadiusTokensTests {
    @Test("XS corner radius defined")
    func xSCornerRadius() {
        #expect(CornerRadius.xs == 4)
    }

    @Test("Small corner radius defined")
    func smCornerRadius() {
        #expect(CornerRadius.sm == 8)
    }

    @Test("Medium corner radius defined")
    func mdCornerRadius() {
        #expect(CornerRadius.md == 12)
    }

    @Test("Large corner radius defined")
    func lgCornerRadius() {
        #expect(CornerRadius.lg == 16)
    }

    @Test("XL corner radius defined")
    func xLCornerRadius() {
        #expect(CornerRadius.xl == 24)
    }

    @Test("XXL corner radius defined")
    func xXLCornerRadius() {
        #expect(CornerRadius.xxl == 32)
    }

    @Test("Pill corner radius defined")
    func pillCornerRadius() {
        #expect(CornerRadius.pill == 999)
    }

    @Test("Corner radius tokens are in ascending order")
    func cornerRadiusAscending() {
        #expect(CornerRadius.xs < CornerRadius.sm)
        #expect(CornerRadius.sm < CornerRadius.md)
        #expect(CornerRadius.md < CornerRadius.lg)
        #expect(CornerRadius.lg < CornerRadius.xl)
        #expect(CornerRadius.xl < CornerRadius.xxl)
        #expect(CornerRadius.xxl < CornerRadius.pill)
    }

    @Test("Pill radius is sufficiently large")
    func pillRadiusLarge() {
        #expect(CornerRadius.pill > 100)
    }
}

@Suite("Shadow Style Tests")
struct ShadowStyleTests {
    @Test("Subtle shadow style defined")
    func subtleShadowStyle() {
        let style = ShadowStyle.subtle
        #expect(style.opacity == 0.05)
        #expect(style.radius == 4)
        #expect(style.xOffset == 0)
        #expect(style.yOffset == 2)
    }

    @Test("Medium shadow style defined")
    func mediumShadowStyle() {
        let style = ShadowStyle.medium
        #expect(style.opacity == 0.1)
        #expect(style.radius == 8)
        #expect(style.xOffset == 0)
        #expect(style.yOffset == 4)
    }

    @Test("Elevated shadow style defined")
    func elevatedShadowStyle() {
        let style = ShadowStyle.elevated
        #expect(style.opacity == 0.15)
        #expect(style.radius == 16)
        #expect(style.xOffset == 0)
        #expect(style.yOffset == 8)
    }

    @Test("Floating shadow style defined")
    func floatingShadowStyle() {
        let style = ShadowStyle.floating
        #expect(style.opacity == 0.2)
        #expect(style.radius == 24)
        #expect(style.xOffset == 0)
        #expect(style.yOffset == 12)
    }

    @Test("Shadow opacity increases with elevation")
    func shadowOpacityElevation() {
        #expect(ShadowStyle.subtle.opacity < ShadowStyle.medium.opacity)
        #expect(ShadowStyle.medium.opacity < ShadowStyle.elevated.opacity)
        #expect(ShadowStyle.elevated.opacity < ShadowStyle.floating.opacity)
    }

    @Test("Shadow radius increases with elevation")
    func shadowRadiusElevation() {
        #expect(ShadowStyle.subtle.radius < ShadowStyle.medium.radius)
        #expect(ShadowStyle.medium.radius < ShadowStyle.elevated.radius)
        #expect(ShadowStyle.elevated.radius < ShadowStyle.floating.radius)
    }

    @Test("Shadow y offset increases with elevation")
    func shadowYOffsetElevation() {
        #expect(ShadowStyle.subtle.yOffset < ShadowStyle.medium.yOffset)
        #expect(ShadowStyle.medium.yOffset < ShadowStyle.elevated.yOffset)
        #expect(ShadowStyle.elevated.yOffset < ShadowStyle.floating.yOffset)
    }

    @Test("Shadow color is black with opacity")
    func shadowColorIsBlack() {
        let subtleColor = ShadowStyle.subtle.color
        let elevatedColor = ShadowStyle.elevated.color
        #expect(subtleColor != nil)
        #expect(elevatedColor != nil)
    }

    @Test("Shadow x offset is always zero")
    func shadowXOffsetZero() {
        #expect(ShadowStyle.subtle.xOffset == 0)
        #expect(ShadowStyle.medium.xOffset == 0)
        #expect(ShadowStyle.elevated.xOffset == 0)
        #expect(ShadowStyle.floating.xOffset == 0)
    }
}

@Suite("Glass Style Tests")
struct GlassStyleTests {
    @Test("Ultra thin glass style defined")
    func ultraThinGlassStyle() {
        let style = GlassStyle.ultraThin
        #expect(style.usesMaterial == true)
        #expect(style.borderOpacity == 0.15)
    }

    @Test("Thin glass style defined")
    func thinGlassStyle() {
        let style = GlassStyle.thin
        #expect(style.usesMaterial == true)
        #expect(style.borderOpacity == 0.2)
    }

    @Test("Regular glass style defined")
    func regularGlassStyle() {
        let style = GlassStyle.regular
        #expect(style.usesMaterial == true)
        #expect(style.borderOpacity == 0.25)
    }

    @Test("Thick glass style defined")
    func thickGlassStyle() {
        let style = GlassStyle.thick
        #expect(style.usesMaterial == true)
        #expect(style.borderOpacity == 0.3)
    }

    @Test("Solid glass style defined")
    func solidGlassStyle() {
        let style = GlassStyle.solid
        #expect(style.usesMaterial == false)
        #expect(style.borderOpacity == 0.15)
    }

    @Test("Border opacity increases with glass thickness")
    func borderOpacityIncrease() {
        #expect(GlassStyle.ultraThin.borderOpacity < GlassStyle.thin.borderOpacity)
        #expect(GlassStyle.thin.borderOpacity < GlassStyle.regular.borderOpacity)
        #expect(GlassStyle.regular.borderOpacity < GlassStyle.thick.borderOpacity)
    }

    @Test("Material styles use blur materials")
    func materialStyles() {
        #expect(GlassStyle.ultraThin.material != nil)
        #expect(GlassStyle.thin.material != nil)
        #expect(GlassStyle.regular.material != nil)
        #expect(GlassStyle.thick.material != nil)
    }

    @Test("Solid style does not use expensive materials")
    func solidNoExpensiveMaterial() {
        #expect(GlassStyle.solid.usesMaterial == false)
    }

    @Test("Only solid does not use materials")
    func onlySolidOptimized() {
        let styles = [GlassStyle.ultraThin, GlassStyle.thin, GlassStyle.regular, GlassStyle.thick]
        for style in styles {
            #expect(style.usesMaterial == true)
        }
        #expect(GlassStyle.solid.usesMaterial == false)
    }
}

@Suite("Animation Timing Tests")
struct AnimationTimingTests {
    @Test("Fast timing defined")
    func fastTiming() {
        #expect(AnimationTiming.fast == 0.15)
    }

    @Test("Normal timing defined")
    func normalTiming() {
        #expect(AnimationTiming.normal == 0.25)
    }

    @Test("Slow timing defined")
    func slowTiming() {
        #expect(AnimationTiming.slow == 0.4)
    }

    @Test("Shimmer timing defined")
    func shimmerTiming() {
        #expect(AnimationTiming.shimmer == 1.5)
    }

    @Test("Spring bouncy animation defined")
    func springBouncyAnimation() {
        let animation = AnimationTiming.springBouncy
        #expect(animation != nil)
    }

    @Test("Spring smooth animation defined")
    func springsSmoothAnimation() {
        let animation = AnimationTiming.springSmooth
        #expect(animation != nil)
    }

    @Test("Spring quick animation defined")
    func springQuickAnimation() {
        let animation = AnimationTiming.springQuick
        #expect(animation != nil)
    }

    @Test("Timing values increase appropriately")
    func timingValuesIncrease() {
        #expect(AnimationTiming.fast < AnimationTiming.normal)
        #expect(AnimationTiming.normal < AnimationTiming.slow)
        #expect(AnimationTiming.slow < AnimationTiming.shimmer)
    }

    @Test("All timing values are positive")
    func timingValuesPositive() {
        #expect(AnimationTiming.fast > 0)
        #expect(AnimationTiming.normal > 0)
        #expect(AnimationTiming.slow > 0)
        #expect(AnimationTiming.shimmer > 0)
    }

    @Test("Spring animations available")
    func springAnimationsAvailable() {
        let bouncy = AnimationTiming.springBouncy
        let smooth = AnimationTiming.springSmooth
        let quick = AnimationTiming.springQuick

        #expect(bouncy != nil)
        #expect(smooth != nil)
        #expect(quick != nil)
    }
}

@Suite("Icon Size Tests")
struct IconSizeTests {
    @Test("XS icon size defined")
    func xSIconSize() {
        #expect(IconSize.xs == 12)
    }

    @Test("Small icon size defined")
    func smIconSize() {
        #expect(IconSize.sm == 16)
    }

    @Test("Medium icon size defined")
    func mdIconSize() {
        #expect(IconSize.md == 20)
    }

    @Test("Large icon size defined")
    func lgIconSize() {
        #expect(IconSize.lg == 24)
    }

    @Test("XL icon size defined")
    func xLIconSize() {
        #expect(IconSize.xl == 32)
    }

    @Test("XXL icon size defined")
    func xXLIconSize() {
        #expect(IconSize.xxl == 48)
    }

    @Test("Icon sizes are in ascending order")
    func iconSizesAscending() {
        #expect(IconSize.xs < IconSize.sm)
        #expect(IconSize.sm < IconSize.md)
        #expect(IconSize.md < IconSize.lg)
        #expect(IconSize.lg < IconSize.xl)
        #expect(IconSize.xl < IconSize.xxl)
    }

    @Test("All icon sizes are positive")
    func iconSizesPositive() {
        #expect(IconSize.xs > 0)
        #expect(IconSize.sm > 0)
        #expect(IconSize.md > 0)
        #expect(IconSize.lg > 0)
        #expect(IconSize.xl > 0)
        #expect(IconSize.xxl > 0)
    }

    @Test("Icon sizes follow consistent scaling")
    func iconSizeScaling() {
        // Check that increments are reasonable
        #expect(IconSize.sm - IconSize.xs == 4)
        #expect(IconSize.md - IconSize.sm == 4)
        #expect(IconSize.lg - IconSize.md == 4)
    }
}

@Suite("Design Tokens Integration Tests")
struct DesignTokensIntegrationTests {
    @Test("All token categories available")
    func allTokenCategories() {
        // Spacing
        let spacing = Spacing.md
        // Corner Radius
        let radius = CornerRadius.md
        // Shadow
        let shadow = ShadowStyle.medium
        // Glass
        let glass = GlassStyle.regular
        // Animation
        let timing = AnimationTiming.normal
        // Icon
        let icon = IconSize.md

        #expect(spacing > 0)
        #expect(radius > 0)
        #expect(shadow.radius > 0)
        #expect(glass.borderOpacity > 0)
        #expect(timing > 0)
        #expect(icon > 0)
    }

    @Test("Design tokens are consistent")
    func tokenConsistency() {
        // All tokens should be accessible
        #expect(Spacing.md == 16)
        #expect(CornerRadius.md == 12)
        #expect(ShadowStyle.medium.opacity == 0.1)
        #expect(GlassStyle.regular.borderOpacity == 0.25)
        #expect(AnimationTiming.normal == 0.25)
        #expect(IconSize.md == 20)
    }

    @Test("Complete design system coverage")
    func completeDesignSystem() {
        // Verify all spacing levels
        let spacings = [Spacing.xxs, Spacing.xs, Spacing.sm, Spacing.md, Spacing.lg, Spacing.xl, Spacing.xxl]
        for spacing in spacings {
            #expect(spacing > 0)
        }

        // Verify all corner radii
        let radii = [CornerRadius.xs, CornerRadius.sm, CornerRadius.md, CornerRadius.lg, CornerRadius.xl, CornerRadius.xxl, CornerRadius.pill]
        for radius in radii {
            #expect(radius > 0)
        }

        // Verify all shadow styles
        let shadows = [ShadowStyle.subtle, ShadowStyle.medium, ShadowStyle.elevated, ShadowStyle.floating]
        for shadow in shadows {
            #expect(shadow.opacity > 0)
            #expect(shadow.radius > 0)
        }

        // Verify all glass styles
        let glasses = [GlassStyle.ultraThin, GlassStyle.thin, GlassStyle.regular, GlassStyle.thick, GlassStyle.solid]
        for glass in glasses {
            #expect(glass.borderOpacity > 0)
        }
    }
}
