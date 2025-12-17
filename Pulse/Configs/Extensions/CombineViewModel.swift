import Foundation
import Combine

protocol CombineViewModel: ObservableObject {
    associatedtype ViewState
    associatedtype ViewEvent

    var viewState: ViewState { get }
    func handle(event: ViewEvent)
}
