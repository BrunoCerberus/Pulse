import Foundation

protocol ViewStateReducing {
    associatedtype DomainState
    associatedtype ViewState

    func reduce(domainState: DomainState) -> ViewState
}
