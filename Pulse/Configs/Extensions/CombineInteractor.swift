import Combine
import Foundation

protocol CombineInteractor {
    associatedtype DomainState
    associatedtype DomainAction

    var statePublisher: AnyPublisher<DomainState, Never> { get }
    func dispatch(action: DomainAction)
}
