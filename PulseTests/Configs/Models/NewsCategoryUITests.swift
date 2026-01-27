import Foundation
@testable import Pulse
import SwiftUI
import Testing

@Suite("NewsCategory UI Tests")
struct NewsCategoryUITests {
    @Test("Display name for business")
    func businessDisplayName() {
        #expect(NewsCategory.business.displayName == "Business")
    }

    @Test("Display name for entertainment")
    func entertainmentDisplayName() {
        #expect(NewsCategory.entertainment.displayName == "Entertainment")
    }

    @Test("Display name for general")
    func generalDisplayName() {
        #expect(NewsCategory.general.displayName == "General")
    }

    @Test("Display name for health")
    func healthDisplayName() {
        #expect(NewsCategory.health.displayName == "Health")
    }

    @Test("Display name for science")
    func scienceDisplayName() {
        #expect(NewsCategory.science.displayName == "Science")
    }

    @Test("Display name for sports")
    func sportsDisplayName() {
        #expect(NewsCategory.sports.displayName == "Sports")
    }

    @Test("Display name for technology")
    func technologyDisplayName() {
        #expect(NewsCategory.technology.displayName == "Technology")
    }

    @Test("Display name for world")
    func worldDisplayName() {
        #expect(NewsCategory.world.displayName == "World")
    }

    @Test("All categories have non-empty display names")
    func allCategoriesHaveDisplayNames() {
        for category in NewsCategory.allCases {
            #expect(!category.displayName.isEmpty, "Category \(category) should have a display name")
        }
    }
}
