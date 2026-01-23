import Foundation
import os

/// Defines memory operation types with different thresholds
enum MemoryOperation {
    case modelLoad
    case inference

    /// Returns the minimum available memory required for this operation
    var minimumMemory: UInt64 {
        switch self {
        case .modelLoad:
            return LLMConfiguration.minimumAvailableMemory
        case .inference:
            return LLMConfiguration.minimumInferenceMemory
        }
    }
}
