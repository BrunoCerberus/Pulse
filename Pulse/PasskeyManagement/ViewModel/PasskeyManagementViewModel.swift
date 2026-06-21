import Combine
import EntropyCore
import Foundation

/// ViewModel for the Passkey Management screen.
@MainActor
final class PasskeyManagementViewModel: CombineViewModel, ObservableObject {
    typealias ViewState = PasskeyManagementViewState
    typealias ViewEvent = PasskeyManagementViewEvent

    @Published private(set) var viewState: PasskeyManagementViewState = .initial
    private let interactor: PasskeyManagementDomainInteractor

    init(serviceLocator: ServiceLocator) {
        interactor = PasskeyManagementDomainInteractor(serviceLocator: serviceLocator)
        setupBindings()
    }

    func handle(event: PasskeyManagementViewEvent) {
        switch event {
        case .onAppear:
            interactor.dispatch(action: .loadPasskeys)
        case let .onDelete(indexSet):
            deletePasskeys(at: indexSet)
        case .registerPasskeyTapped:
            interactor.dispatch(action: .registerPasskey)
        case .onDismissError:
            interactor.dispatch(action: .clearError)
        }
    }

    private func deletePasskeys(at indexSet: IndexSet) {
        let usernames: [String] = indexSet.compactMap { index -> String? in
            guard index < viewState.passkeys.count else { return nil }
            return viewState.passkeys[index]
        }
        for username in usernames {
            interactor.dispatch(action: .deletePasskey(username: username))
        }
    }

    private func setupBindings() {
        interactor.statePublisher
            .map { state in
                PasskeyManagementViewState(
                    passkeys: state.passkeys,
                    isLoading: state.isLoading,
                    errorMessage: state.error
                )
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$viewState)
    }
}

struct PasskeyManagementViewState: Equatable {
    var passkeys: [String]
    var isLoading: Bool
    var errorMessage: String?

    static var initial: PasskeyManagementViewState {
        PasskeyManagementViewState(
            passkeys: [],
            isLoading: false,
            errorMessage: nil
        )
    }
}

enum PasskeyManagementViewEvent {
    case onAppear
    case onDelete(indexSet: IndexSet)
    case registerPasskeyTapped
    case onDismissError
}
