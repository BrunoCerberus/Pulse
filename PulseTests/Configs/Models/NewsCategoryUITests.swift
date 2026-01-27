import Foundation
@testable import Pulse
import SwiftUI
import Testing

@Suite("NewsCategory UI Tests")
struct NewsCategoryUITests {
    @Test("Display name for business is not empty")
    func businessDisplayName() {
        #expect(!NewsCategory.business.displayName.isEmpty)
    }

    @Test("Display name for entertainment is not empty")
    func entertainmentDisplayName() {
        #expect(!NewsCategory.entertainment.displayName.isEmpty)
    }

    @Test("Display name for health is not empty")
    func healthDisplayName() {
        #expect(!NewsCategory.health.displayName.isEmpty)
    }

    @Test("Display name for science is not empty")
    func scienceDisplayName() {
        #expect(!NewsCategory.science.displayName.isEmpty)
    }

    @Test("Display name for sports is not empty")
    func sportsDisplayName() {
        #expect(!NewsCategory.sports.displayName.isEmpty)
    }

    @Test("Display name for technology is not empty")
    func technologyDisplayName() {
        #expect(!NewsCategory.technology.displayName.isEmpty)
    }

    @Test("Display name for world is not empty")
    func worldDisplayName() {
        #expect(!NewsCategory.world.displayName.isEmpty)
    }

    @Test("All categories have non-empty display names")
    func allCategoriesHaveDisplayNames() {
        for category in NewsCategory.allCases {
            #expect(!category.displayName.isEmpty, "Category \(category) should have a display name")
        }
    }

    @Test("All categories have non-empty icons")
    func allCategoriesHaveIcons() {
        for category in NewsCategory.allCases {
            #expect(!category.icon.isEmpty, "Category \(category) should have an icon")
        }
    }

    @Test("All categories have valid API parameters")
    func allCategoriesHaveApiParameters() {
        for category in NewsCategory.allCases {
            #expect(!category.apiParameter.isEmpty, "Category \(category) should have an API parameter")
        }
    }

    @Test("All categories have valid Guardian sections")
    func allCategoriesHaveGuardianSections() {
        for category in NewsCategory.allCases {
            #expect(!category.guardianSection.isEmpty, "Category \(category) should have a Guardian section")
        }
    }
}
