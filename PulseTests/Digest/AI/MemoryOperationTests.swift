import Foundation
@testable import Pulse
import Testing

@Suite("MemoryOperation Tests")
struct MemoryOperationTests {
    // MARK: - Enum Cases Tests

    @Test("MemoryOperation has all cases")
    func hasAllCases() {
        let allCases: [MemoryOperation] = [.modelLoad, .inference]
        #expect(allCases.count == 2)
    }

    @Test("MemoryOperation modelLoad case exists")
    func modelLoadCaseExists() {
        let operation = MemoryOperation.modelLoad
        // Should be able to switch on the case
        switch operation {
        case .modelLoad:
            #expect(true)
        case .inference:
            Issue.record("Should be modelLoad case")
        }
    }

    @Test("MemoryOperation inference case exists")
    func inferenceCaseExists() {
        let operation = MemoryOperation.inference
        // Should be able to switch on the case
        switch operation {
        case .modelLoad:
            Issue.record("Should be inference case")
        case .inference:
            #expect(true)
        }
    }

    // MARK: - minimumMemory Property Tests

    @Test("MemoryOperation modelLoad minimumMemory returns correct value")
    func modelLoadMinimumMemoryReturnsCorrectValue() {
        let operation = MemoryOperation.modelLoad
        let expectedMemory = LLMConfiguration.minimumAvailableMemory
        #expect(operation.minimumMemory == expectedMemory)
    }

    @Test("MemoryOperation inference minimumMemory returns correct value")
    func inferenceMinimumMemoryReturnsCorrectValue() {
        let operation = MemoryOperation.inference
        let expectedMemory = LLMConfiguration.minimumInferenceMemory
        #expect(operation.minimumMemory == expectedMemory)
    }

    @Test("MemoryOperation modelLoad minimumMemory is greater than inference minimumMemory")
    func modelLoadMinimumMemoryGreaterThanInference() {
        let modelLoadMemory = MemoryOperation.modelLoad.minimumMemory
        let inferenceMemory = MemoryOperation.inference.minimumMemory
        #expect(modelLoadMemory > inferenceMemory)
    }

    @Test("MemoryOperation minimumMemory matches LLMConfiguration values")
    func minimumMemoryMatchesLLMConfiguration() {
        #expect(MemoryOperation.modelLoad.minimumMemory == LLMConfiguration.minimumAvailableMemory)
        #expect(MemoryOperation.inference.minimumMemory == LLMConfiguration.minimumInferenceMemory)
    }

    @Test("MemoryOperation minimumMemory returns positive values")
    func minimumMemoryReturnsPositiveValues() {
        #expect(MemoryOperation.modelLoad.minimumMemory > 0)
        #expect(MemoryOperation.inference.minimumMemory > 0)
    }
}
