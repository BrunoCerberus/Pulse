import Combine

/// A domain interactor protocol for Combine-based unidirectional data flow.
protocol CombineInteractor {
    associatedtype DomainState: Equatable
    associatedtype DomainAction

    var statePublisher: AnyPublisher<DomainState, Never> { get }

    func dispatch(action: DomainAction)
}
