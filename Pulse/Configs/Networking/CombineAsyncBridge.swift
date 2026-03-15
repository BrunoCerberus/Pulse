import Combine
import Foundation

/// A `@unchecked Sendable` box that allows non-Sendable values to cross
/// isolation boundaries inside `Task` closures.
///
/// This is needed because `Future + Task` is a common Combine-to-async bridge
/// pattern, but Swift 6.2's strict `sending` checks reject capturing the
/// `promise` callback (non-Sendable closure) in a `Task`.
///
/// Usage is limited to bridging patterns where the value is consumed exactly
/// once inside the Task and never aliased.
struct UncheckedSendableBox<T>: @unchecked Sendable {
    let value: T
}

/// A weak reference wrapper that avoids `[weak self]` capture issues with Swift 6.2's
/// strict `sending` checks. `[weak self]` creates a mutable `Optional` variable that
/// the compiler rejects in `sending` closures.
final class WeakRef<T: AnyObject>: @unchecked Sendable {
    weak var object: T?

    init(_ object: T) {
        self.object = object
    }
}
