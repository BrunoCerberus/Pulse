import SwiftUI

enum HomeCoordinator {
    static func start(serviceLocator: ServiceLocator) -> some View {
        HomeView(serviceLocator: serviceLocator)
    }
}
