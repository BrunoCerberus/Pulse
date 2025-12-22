import Combine

/// A ViewModel protocol for Combine-based unidirectional data flow.
protocol CombineViewModel: ObservableObject {
    associatedtype ViewState: Equatable
    associatedtype ViewEvent

    var viewState: ViewState { get }

    func handle(event: ViewEvent)
}
