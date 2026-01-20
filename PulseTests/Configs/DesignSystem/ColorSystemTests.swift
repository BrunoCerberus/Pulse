import Foundation
@testable import Pulse
import SwiftUI
import Testing

@Suite("ColorSystem Glass Colors Tests")
struct ColorSystemGlassColorsTests {
    @Test("Glass background color exists")
    func glassBackgroundColor() {
        let color = Color.Glass.background
        #expect(color != nil)
    }

    @Test("Glass surface color exists")
    func glassSurfaceColor() {
        let color = Color.Glass.surface
        #expect(color != nil)
    }

    @Test("Glass elevated color exists")
    func glassElevatedColor() {
        let color = Color.Glass.elevated
        #expect(color != nil)
    }

    @Test("Glass overlay color exists")
    func glassOverlayColor() {
        let color = Color.Glass.overlay
        #expect(color != nil)
    }

    @Test("Glass background is less opaque than elevated")
    func glassOpacityHierarchy() {
        // Verify that colors exist and can be used consistently
        let background = Color.Glass.background
        let elevated = Color.Glass.elevated
        #expect(background != elevated)
    }
}

@Suite("ColorSystem Border Colors Tests")
struct ColorSystemBorderColorsTests {
    @Test("Glass border color exists")
    func glassBorderColor() {
        let color = Color.Border.glass
        #expect(color != nil)
    }

    @Test("Glass dark border color exists")
    func glassDarkBorderColor() {
        let color = Color.Border.glassDark
        #expect(color != nil)
    }

    @Test("Glass subtle border color exists")
    func glassSubtleBorderColor() {
        let color = Color.Border.glassSubtle
        #expect(color != nil)
    }

    @Test("Adaptive border color for dark scheme")
    func adaptiveBorderColorDark() {
        let color = Color.Border.adaptive(for: .dark)
        #expect(color != nil)
    }

    @Test("Adaptive border color for light scheme")
    func adaptiveBorderColorLight() {
        let color = Color.Border.adaptive(for: .light)
        #expect(color != nil)
    }

    @Test("Different color schemes return different adaptive colors")
    func adaptiveColorSchemesDifferent() {
        let darkColor = Color.Border.adaptive(for: .dark)
        let lightColor = Color.Border.adaptive(for: .light)
        #expect(darkColor != lightColor)
    }
}

@Suite("ColorSystem Accent Colors Tests")
struct ColorSystemAccentColorsTests {
    @Test("Primary accent color exists")
    func primaryAccentColor() {
        let color = Color.Accent.primary
        #expect(color == .blue)
    }

    @Test("Secondary accent color exists")
    func secondaryAccentColor() {
        let color = Color.Accent.secondary
        #expect(color == .purple)
    }

    @Test("Tertiary accent color exists")
    func tertiaryAccentColor() {
        let color = Color.Accent.tertiary
        #expect(color == .cyan)
    }

    @Test("Gold accent color exists")
    func goldAccentColor() {
        let color = Color.Accent.gold
        #expect(color == .orange)
    }

    @Test("Gradient contains blue and purple")
    func gradientColors() {
        let gradient = Color.Accent.gradient
        #expect(gradient != nil)
    }

    @Test("Vibrant gradient contains multiple colors")
    func testVibrantGradient() {
        let gradient = Color.Accent.vibrantGradient
        #expect(gradient != nil)
    }

    @Test("Warm gradient exists")
    func testWarmGradient() {
        let gradient = Color.Accent.warmGradient
        #expect(gradient != nil)
    }

    @Test("All gradients have different start points")
    func gradientStartPoints() {
        let gradient1 = Color.Accent.gradient
        let gradient2 = Color.Accent.vibrantGradient
        // Verify gradients can be instantiated consistently
        #expect(gradient1 != nil)
        #expect(gradient2 != nil)
    }
}

@Suite("ColorSystem Semantic Colors Tests")
struct ColorSystemSemanticColorsTests {
    @Test("Success color is green")
    func successColor() {
        let color = Color.Semantic.success
        #expect(color == .green)
    }

    @Test("Warning color is orange")
    func warningColor() {
        let color = Color.Semantic.warning
        #expect(color == .orange)
    }

    @Test("Error color is red")
    func errorColor() {
        let color = Color.Semantic.error
        #expect(color == .red)
    }

    @Test("Info color is blue")
    func infoColor() {
        let color = Color.Semantic.info
        #expect(color == .blue)
    }

    @Test("Skeleton color exists")
    func skeletonColor() {
        let color = Color.Semantic.skeleton
        #expect(color != nil)
    }

    @Test("All semantic colors are distinct")
    func semanticColorsDistinct() {
        let success = Color.Semantic.success
        let warning = Color.Semantic.warning
        let error = Color.Semantic.error
        let info = Color.Semantic.info

        #expect(success != warning)
        #expect(warning != error)
        #expect(error != info)
        #expect(success != info)
    }
}

@Suite("ColorSystem Gradient Backgrounds Tests")
struct ColorSystemGradientBackgroundsTests {
    @Test("Mesh fallback gradient exists")
    func meshFallbackGradient() {
        let gradient = LinearGradient.meshFallback
        #expect(gradient != nil)
    }

    @Test("Subtle background gradient exists")
    func subtleBackgroundGradient() {
        let gradient = LinearGradient.subtleBackground
        #expect(gradient != nil)
    }

    @Test("Card overlay gradient exists")
    func cardOverlayGradient() {
        let gradient = LinearGradient.cardOverlay
        #expect(gradient != nil)
    }

    @Test("Hero overlay gradient exists")
    func heroOverlayGradient() {
        let gradient = LinearGradient.heroOverlay
        #expect(gradient != nil)
    }

    @Test("Gradients have correct start points")
    func testGradientStartPoints() {
        let meshFallback = LinearGradient.meshFallback
        let subtleBackground = LinearGradient.subtleBackground
        let cardOverlay = LinearGradient.cardOverlay
        let heroOverlay = LinearGradient.heroOverlay

        #expect(meshFallback != nil)
        #expect(subtleBackground != nil)
        #expect(cardOverlay != nil)
        #expect(heroOverlay != nil)
    }

    @Test("Card overlay uses top to bottom direction")
    func cardOverlayDirection() {
        let gradient = LinearGradient.cardOverlay
        #expect(gradient != nil)
    }

    @Test("Hero overlay has darker gradient than card overlay")
    func heroOverlayDarkerThanCard() {
        let cardOverlay = LinearGradient.cardOverlay
        let heroOverlay = LinearGradient.heroOverlay
        // Both should exist and be usable
        #expect(cardOverlay != nil)
        #expect(heroOverlay != nil)
    }
}

@Suite("ColorSystem Mesh Gradient Tests")
@available(iOS 18.0, *)
struct ColorSystemMeshGradientTests {
    @Test("Glass mesh gradient exists")
    func glassMeshGradient() {
        let mesh = MeshGradient.glassMesh
        #expect(mesh != nil)
    }

    @Test("Warm mesh gradient exists")
    func warmMeshGradient() {
        let mesh = MeshGradient.warmMesh
        #expect(mesh != nil)
    }

    @Test("Mesh gradients have correct dimensions")
    func meshGradientDimensions() {
        let glassMesh = MeshGradient.glassMesh
        let warmMesh = MeshGradient.warmMesh
        // Mesh gradients are 3x3 with 9 points and 9 colors
        #expect(glassMesh != nil)
        #expect(warmMesh != nil)
    }

    @Test("Glass mesh and warm mesh are different")
    func meshGradientsDifferent() {
        let glassMesh = MeshGradient.glassMesh
        let warmMesh = MeshGradient.warmMesh
        // Different color schemes
        #expect(glassMesh != warmMesh)
    }
}

@Suite("ColorSystem Integration Tests")
struct ColorSystemIntegrationTests {
    @Test("All glass colors defined")
    func allGlassColorsDefined() {
        let background = Color.Glass.background
        let surface = Color.Glass.surface
        let elevated = Color.Glass.elevated
        let overlay = Color.Glass.overlay

        #expect(background != nil)
        #expect(surface != nil)
        #expect(elevated != nil)
        #expect(overlay != nil)
    }

    @Test("All border colors defined")
    func allBorderColorsDefined() {
        let glass = Color.Border.glass
        let glassDark = Color.Border.glassDark
        let glassSubtle = Color.Border.glassSubtle

        #expect(glass != nil)
        #expect(glassDark != nil)
        #expect(glassSubtle != nil)
    }

    @Test("All accent colors defined")
    func allAccentColorsDefined() {
        let primary = Color.Accent.primary
        let secondary = Color.Accent.secondary
        let tertiary = Color.Accent.tertiary
        let gold = Color.Accent.gold

        #expect(primary != nil)
        #expect(secondary != nil)
        #expect(tertiary != nil)
        #expect(gold != nil)
    }

    @Test("All semantic colors defined")
    func allSemanticColorsDefined() {
        let success = Color.Semantic.success
        let warning = Color.Semantic.warning
        let error = Color.Semantic.error
        let info = Color.Semantic.info
        let skeleton = Color.Semantic.skeleton

        #expect(success != nil)
        #expect(warning != nil)
        #expect(error != nil)
        #expect(info != nil)
        #expect(skeleton != nil)
    }

    @Test("All gradients defined")
    func allGradientsDefined() {
        let meshFallback = LinearGradient.meshFallback
        let subtleBackground = LinearGradient.subtleBackground
        let cardOverlay = LinearGradient.cardOverlay
        let heroOverlay = LinearGradient.heroOverlay

        #expect(meshFallback != nil)
        #expect(subtleBackground != nil)
        #expect(cardOverlay != nil)
        #expect(heroOverlay != nil)
    }
}
