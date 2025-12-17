import Foundation

final class ServiceLocator {
    static let shared = ServiceLocator()

    private var services: [String: Any] = [:]
    private let lock = NSLock()

    private init() {}

    func register<T>(_ type: T.Type, service: T) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        services[key] = service
    }

    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        guard let service = services[key] as? T else {
            fatalError("Service \(key) not registered. Call register(_:service:) first.")
        }
        return service
    }

    func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        return services[key] as? T
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        services.removeAll()
    }
}
