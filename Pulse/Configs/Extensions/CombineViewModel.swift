import Combine
import Foundation

protocol CombineViewModel: ObservableObject {
    associatedtype ViewState
    associatedtype ViewEvent

    var viewState: ViewState { get }
    func handle(event: ViewEvent)
}
