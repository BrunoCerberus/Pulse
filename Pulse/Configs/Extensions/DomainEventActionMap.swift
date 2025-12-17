import Foundation

protocol DomainEventActionMap {
    associatedtype ViewEvent
    associatedtype DomainAction

    func map(event: ViewEvent) -> DomainAction?
}
