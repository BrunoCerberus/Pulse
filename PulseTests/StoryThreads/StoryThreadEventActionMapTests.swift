import Foundation
@testable import Pulse
import Testing

@Suite("StoryThreadEventActionMap Tests")
struct StoryThreadEventActionMapTests {
    let sut = StoryThreadEventActionMap()
    private let testID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    // MARK: - Event Mapping Tests

    @Test("All events map to correct actions")
    func allEventsMappingToCorrectActions() {
        #expect(sut.map(event: .onAppear) == .loadFollowedThreads)
        #expect(sut.map(event: .didToggleFollow(id: testID)) == .unfollowThread(id: testID))
        #expect(sut.map(event: .didRequestSummary(id: testID)) == .generateSummary(threadID: testID))
        #expect(sut.map(event: .didPullToRefresh) == .refresh)
    }

    @Test("didTapThread returns nil (navigation handled by router)")
    func didTapThreadReturnsNil() {
        let action = sut.map(event: .didTapThread(id: testID))
        #expect(action == nil)
    }

    // MARK: - Associated Value Preservation

    @Test("didToggleFollow preserves thread ID")
    func didToggleFollowPreservesId() throws {
        let id1 = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let id2 = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))

        #expect(sut.map(event: .didToggleFollow(id: id1)) == .unfollowThread(id: id1))
        #expect(sut.map(event: .didToggleFollow(id: id2)) == .unfollowThread(id: id2))
    }

    @Test("didRequestSummary preserves thread ID")
    func didRequestSummaryPreservesId() throws {
        let id1 = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let id2 = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))

        #expect(sut.map(event: .didRequestSummary(id: id1)) == .generateSummary(threadID: id1))
        #expect(sut.map(event: .didRequestSummary(id: id2)) == .generateSummary(threadID: id2))
    }

    // MARK: - Non-nil Actions Check

    @Test("All events except didTapThread produce non-nil actions")
    func allEventsExceptTapProduceActions() {
        let events: [StoryThreadViewEvent] = [
            .onAppear,
            .didToggleFollow(id: testID),
            .didRequestSummary(id: testID),
            .didPullToRefresh,
        ]

        for event in events {
            let action = sut.map(event: event)
            #expect(action != nil)
        }
    }
}
