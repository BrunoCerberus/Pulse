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

// MARK: - Simulator Warning State

/// Reference type wrapper for simulator warning state.
/// Required because OSAllocatedUnfairLock needs a reference type to properly
/// synchronize mutable state across threads.
final class SimulatorWarningState: @unchecked Sendable {
    var hasLogged = false
}

/// Thread-safe static lock for one-time simulator warning log.
/// Using a lock ensures the warning is logged exactly once even under concurrent access.
let simulatorWarningLock = OSAllocatedUnfairLock(initialState: SimulatorWarningState())
