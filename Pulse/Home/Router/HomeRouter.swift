import Foundation

enum HomeRoute: Hashable {
    case articleDetail(Article)
    case search
    case categories
}

protocol HomeRouting {
    func navigate(to route: HomeRoute)
}

final class HomeRouter: HomeRouting {
    weak var coordinator: HomeCoordinatorDelegate?

    func navigate(to route: HomeRoute) {
        coordinator?.navigateTo(route: route)
    }
}

protocol HomeCoordinatorDelegate: AnyObject {
    func navigateTo(route: HomeRoute)
}
