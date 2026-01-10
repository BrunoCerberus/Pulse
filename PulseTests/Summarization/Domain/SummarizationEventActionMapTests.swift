import Foundation
@testable import Pulse
import Testing

@Suite("SummarizationEventActionMap Tests")
struct SummarizationEventActionMapTests {
    let sut = SummarizationEventActionMap()

    // MARK: - Event Mapping Tests

    @Test("All events map to correct actions")
    func allEventsMappingToCorrectActions() {
        #expect(sut.map(event: .onSummarizationStarted) == .startSummarization)
        #expect(sut.map(event: .onSummarizationCancelled) == .cancelSummarization)
    }

    // MARK: - All Events Have Mappings

    @Test("All events produce non-nil actions")
    func allEventsProduceActions() {
        let events: [SummarizationViewEvent] = [
            .onSummarizationStarted,
            .onSummarizationCancelled,
        ]

        for event in events {
            let action = sut.map(event: event)
            #expect(action != nil)
        }
    }
}
