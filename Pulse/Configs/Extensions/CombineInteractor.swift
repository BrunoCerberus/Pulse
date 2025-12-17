import Foundation
import Combine

protocol CombineInteractor {
    associatedtype DomainState
    associatedtype DomainAction

    var statePublisher: AnyPublisher<DomainState, Never> { get }
    func dispatch(action: DomainAction)
}
