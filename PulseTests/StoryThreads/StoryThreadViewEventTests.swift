import Foundation
@testable import Pulse
import Testing

@Suite("StoryThreadViewEvent Tests")
struct StoryThreadViewEventTests {
    private let testID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let testID2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    @Test("StoryThreadViewEvent cases are Equatable")
    func equatable() {
        #expect(StoryThreadViewEvent.onAppear == StoryThreadViewEvent.onAppear)
        #expect(StoryThreadViewEvent.didPullToRefresh == StoryThreadViewEvent.didPullToRefresh)
    }

    @Test("didTapThread carries thread ID")
    func didTapThreadCarriesId() {
        let event1 = StoryThreadViewEvent.didTapThread(id: testID)
        let event2 = StoryThreadViewEvent.didTapThread(id: testID)
        let event3 = StoryThreadViewEvent.didTapThread(id: testID2)

        #expect(event1 == event2)
        #expect(event1 != event3)
    }

    @Test("didToggleFollow carries thread ID")
    func didToggleFollowCarriesId() {
        let event1 = StoryThreadViewEvent.didToggleFollow(id: testID)
        let event2 = StoryThreadViewEvent.didToggleFollow(id: testID)
        let event3 = StoryThreadViewEvent.didToggleFollow(id: testID2)

        #expect(event1 == event2)
        #expect(event1 != event3)
    }

    @Test("didRequestSummary carries thread ID")
    func didRequestSummaryCarriesId() {
        let event1 = StoryThreadViewEvent.didRequestSummary(id: testID)
        let event2 = StoryThreadViewEvent.didRequestSummary(id: testID)
        let event3 = StoryThreadViewEvent.didRequestSummary(id: testID2)

        #expect(event1 == event2)
        #expect(event1 != event3)
    }

    @Test("Different event types are not equal")
    func differentTypesNotEqual() {
        #expect(StoryThreadViewEvent.onAppear != StoryThreadViewEvent.didPullToRefresh)
        #expect(StoryThreadViewEvent.didTapThread(id: testID) != StoryThreadViewEvent.didToggleFollow(id: testID))
        #expect(StoryThreadViewEvent.didToggleFollow(id: testID) != StoryThreadViewEvent.didRequestSummary(id: testID))
    }
}
