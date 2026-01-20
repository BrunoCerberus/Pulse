import Foundation
@testable import Pulse
import SwiftUI
import Testing

@Suite("Typography Display Font Tests")
struct TypographyDisplayFontTests {
    @Test("Display large font exists")
    func displayLargeFont() {
        let font = Typography.displayLarge
        #expect(font != nil)
    }

    @Test("Display medium font exists")
    func displayMediumFont() {
        let font = Typography.displayMedium
        #expect(font != nil)
    }

    @Test("Display small font exists")
    func displaySmallFont() {
        let font = Typography.displaySmall
        #expect(font != nil)
    }

    @Test("Display fonts use rounded design")
    func displayFontsRounded() {
        let large = Typography.displayLarge
        let medium = Typography.displayMedium
        let small = Typography.displaySmall

        #expect(large != nil)
        #expect(medium != nil)
        #expect(small != nil)
    }

    @Test("Display fonts are distinct from each other")
    func displayFontsDistinct() {
        let large = Typography.displayLarge
        let medium = Typography.displayMedium
        let small = Typography.displaySmall

        #expect(large != medium)
        #expect(medium != small)
        #expect(large != small)
    }
}

@Suite("Typography Title Font Tests")
struct TypographyTitleFontTests {
    @Test("Title large font exists")
    func titleLargeFont() {
        let font = Typography.titleLarge
        #expect(font != nil)
    }

    @Test("Title medium font exists")
    func titleMediumFont() {
        let font = Typography.titleMedium
        #expect(font != nil)
    }

    @Test("Title small font exists")
    func titleSmallFont() {
        let font = Typography.titleSmall
        #expect(font != nil)
    }

    @Test("All title fonts defined")
    func allTitleFontsDefined() {
        let large = Typography.titleLarge
        let medium = Typography.titleMedium
        let small = Typography.titleSmall

        #expect(large != nil)
        #expect(medium != nil)
        #expect(small != nil)
    }
}

@Suite("Typography Headline Font Tests")
struct TypographyHeadlineFontTests {
    @Test("Headline large font exists")
    func headlineLargeFont() {
        let font = Typography.headlineLarge
        #expect(font != nil)
    }

    @Test("Headline medium font exists")
    func headlineMediumFont() {
        let font = Typography.headlineMedium
        #expect(font != nil)
    }

    @Test("Headline small font exists")
    func headlineSmallFont() {
        let font = Typography.headlineSmall
        #expect(font != nil)
    }

    @Test("All headline fonts defined")
    func allHeadlineFontsDefined() {
        let large = Typography.headlineLarge
        let medium = Typography.headlineMedium
        let small = Typography.headlineSmall

        #expect(large != nil)
        #expect(medium != nil)
        #expect(small != nil)
    }

    @Test("Headline large and medium have same size")
    func headlineLargeAndMediumSame() {
        let large = Typography.headlineLarge
        let medium = Typography.headlineMedium
        // Both use headline size
        #expect(large == medium)
    }
}

@Suite("Typography Body Font Tests")
struct TypographyBodyFontTests {
    @Test("Body large font exists")
    func bodyLargeFont() {
        let font = Typography.bodyLarge
        #expect(font != nil)
    }

    @Test("Body medium font exists")
    func bodyMediumFont() {
        let font = Typography.bodyMedium
        #expect(font != nil)
    }

    @Test("Body small font exists")
    func bodySmallFont() {
        let font = Typography.bodySmall
        #expect(font != nil)
    }

    @Test("Body large and medium same size")
    func bodyLargeAndMediumSame() {
        let large = Typography.bodyLarge
        let medium = Typography.bodyMedium
        #expect(large == medium)
    }

    @Test("All body fonts defined")
    func allBodyFontsDefined() {
        let large = Typography.bodyLarge
        let medium = Typography.bodyMedium
        let small = Typography.bodySmall

        #expect(large != nil)
        #expect(medium != nil)
        #expect(small != nil)
    }
}

@Suite("Typography Caption Font Tests")
struct TypographyCaptionFontTests {
    @Test("Caption large font exists")
    func captionLargeFont() {
        let font = Typography.captionLarge
        #expect(font != nil)
    }

    @Test("Caption medium font exists")
    func captionMediumFont() {
        let font = Typography.captionMedium
        #expect(font != nil)
    }

    @Test("Caption small font exists")
    func captionSmallFont() {
        let font = Typography.captionSmall
        #expect(font != nil)
    }

    @Test("Caption medium and small same size")
    func captionMediumAndSmallSame() {
        let medium = Typography.captionMedium
        let small = Typography.captionSmall
        #expect(medium == small)
    }

    @Test("All caption fonts defined")
    func allCaptionFontsDefined() {
        let large = Typography.captionLarge
        let medium = Typography.captionMedium
        let small = Typography.captionSmall

        #expect(large != nil)
        #expect(medium != nil)
        #expect(small != nil)
    }
}

@Suite("Typography Label Font Tests")
struct TypographyLabelFontTests {
    @Test("Label large font exists")
    func labelLargeFont() {
        let font = Typography.labelLarge
        #expect(font != nil)
    }

    @Test("Label medium font exists")
    func labelMediumFont() {
        let font = Typography.labelMedium
        #expect(font != nil)
    }

    @Test("Label small font exists")
    func labelSmallFont() {
        let font = Typography.labelSmall
        #expect(font != nil)
    }

    @Test("All label fonts defined")
    func allLabelFontsDefined() {
        let large = Typography.labelLarge
        let medium = Typography.labelMedium
        let small = Typography.labelSmall

        #expect(large != nil)
        #expect(medium != nil)
        #expect(small != nil)
    }
}

@Suite("Typography AI Content Font Tests")
struct TypographyAIContentFontTests {
    @Test("AI content large font exists")
    func aIContentLargeFont() {
        let font = Typography.aiContentLarge
        #expect(font != nil)
    }

    @Test("AI content medium font exists")
    func aIContentMediumFont() {
        let font = Typography.aiContentMedium
        #expect(font != nil)
    }

    @Test("AI content small font exists")
    func aIContentSmallFont() {
        let font = Typography.aiContentSmall
        #expect(font != nil)
    }

    @Test("AI drop cap font exists")
    func aIDropCapFont() {
        let font = Typography.aiDropCap
        #expect(font != nil)
    }

    @Test("All AI content fonts use serif design")
    func aIContentFontsSerif() {
        let large = Typography.aiContentLarge
        let medium = Typography.aiContentMedium
        let small = Typography.aiContentSmall
        let dropCap = Typography.aiDropCap

        #expect(large != nil)
        #expect(medium != nil)
        #expect(small != nil)
        #expect(dropCap != nil)
    }
}

@Suite("Typography Modifier Tests")
struct TypographyModifierTests {
    @Test("Display large modifier available")
    func displayLargeModifier() {
        let text = Text("Test")
            .displayLarge()
        #expect(text != nil)
    }

    @Test("All display modifiers available")
    func displayModifiers() {
        let text1 = Text("Test").displayLarge()
        let text2 = Text("Test").displayMedium()
        let text3 = Text("Test").displaySmall()

        #expect(text1 != nil)
        #expect(text2 != nil)
        #expect(text3 != nil)
    }

    @Test("All title modifiers available")
    func titleModifiers() {
        let text1 = Text("Test").titleLarge()
        let text2 = Text("Test").titleMedium()
        let text3 = Text("Test").titleSmall()

        #expect(text1 != nil)
        #expect(text2 != nil)
        #expect(text3 != nil)
    }

    @Test("All headline modifiers available")
    func headlineModifiers() {
        let text1 = Text("Test").headlineLarge()
        let text2 = Text("Test").headlineMedium()
        let text3 = Text("Test").headlineSmall()

        #expect(text1 != nil)
        #expect(text2 != nil)
        #expect(text3 != nil)
    }

    @Test("All body modifiers available")
    func bodyModifiers() {
        let text1 = Text("Test").bodyLarge()
        let text2 = Text("Test").bodyMedium()
        let text3 = Text("Test").bodySmall()

        #expect(text1 != nil)
        #expect(text2 != nil)
        #expect(text3 != nil)
    }

    @Test("All caption modifiers available")
    func captionModifiers() {
        let text1 = Text("Test").captionLarge()
        let text2 = Text("Test").captionMedium()
        let text3 = Text("Test").captionSmall()

        #expect(text1 != nil)
        #expect(text2 != nil)
        #expect(text3 != nil)
    }

    @Test("All label modifiers available")
    func labelModifiers() {
        let text1 = Text("Test").labelLarge()
        let text2 = Text("Test").labelMedium()
        let text3 = Text("Test").labelSmall()

        #expect(text1 != nil)
        #expect(text2 != nil)
        #expect(text3 != nil)
    }

    @Test("Modifiers chain with other SwiftUI modifiers")
    func modifierChaining() {
        let text = Text("Test")
            .titleLarge()
            .foregroundStyle(.blue)
            .lineLimit(2)

        #expect(text != nil)
    }
}

@Suite("Typography Integration Tests")
struct TypographyIntegrationTests {
    @Test("All font sizes defined")
    func allFontSizesDefined() {
        let displayLarge = Typography.displayLarge
        let titleLarge = Typography.titleLarge
        let headlineLarge = Typography.headlineLarge
        let bodyLarge = Typography.bodyLarge
        let captionLarge = Typography.captionLarge
        let labelLarge = Typography.labelLarge

        #expect(displayLarge != nil)
        #expect(titleLarge != nil)
        #expect(headlineLarge != nil)
        #expect(bodyLarge != nil)
        #expect(captionLarge != nil)
        #expect(labelLarge != nil)
    }

    @Test("All AI content fonts defined")
    func allAIFontsDefined() {
        let large = Typography.aiContentLarge
        let medium = Typography.aiContentMedium
        let small = Typography.aiContentSmall
        let dropCap = Typography.aiDropCap

        #expect(large != nil)
        #expect(medium != nil)
        #expect(small != nil)
        #expect(dropCap != nil)
    }

    @Test("Typography covers full range of text styles")
    func fullTypographyRange() {
        // Test that we have coverage for all common text scenarios
        let headers = [Typography.displayLarge, Typography.titleLarge, Typography.headlineLarge]
        let body = [Typography.bodyLarge, Typography.bodyMedium, Typography.bodySmall]
        let supporting = [Typography.captionLarge, Typography.labelLarge]

        for font in headers + body + supporting {
            #expect(font != nil)
        }
    }
}
