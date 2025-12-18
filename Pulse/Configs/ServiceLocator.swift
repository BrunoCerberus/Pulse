import Foundation

/**
 * Service Locator pattern implementation for dependency injection.
 *
 * This class manages service dependencies and provides a centralized way
 * to register and retrieve services by their protocol type. It supports
 * both singleton and factory-based service registration.
 *
 * Features:
 * - Type-safe service retrieval using protocols
 * - Support for both singleton and factory patterns
 * - Automatic test environment detection for mock services
 * - Thread-safe service registration and retrieval
 */
final class ServiceLocator {
    /// Dictionary to store service factories by protocol type
    private var services: [String: Any] = [:]

    /// Thread-safe queue for service registration and retrieval
    private let queue: DispatchQueue = .init(label: "com.bruno.Pulse.ServiceLocator", attributes: .concurrent)

    /**
     * Initialize a new ServiceLocator instance.
     */
    init() {}

    /**
     * Register a service factory for a specific protocol type.
     *
     * - Parameter serviceType: The protocol type to register
     * - Parameter factory: Closure that creates the service instance
     */
    func register<T>(_ serviceType: T.Type, factory: @escaping () -> T) {
        let key = String(describing: serviceType)
        queue.async(flags: .barrier) {
            self.services[key] = factory
        }
    }

    /**
     * Register a service instance for a specific protocol type.
     *
     * - Parameter serviceType: The protocol type to register
     * - Parameter instance: The singleton service instance
     */
    func register<T>(_ serviceType: T.Type, instance: T) {
        let key = String(describing: serviceType)
        queue.async(flags: .barrier) {
            self.services[key] = { instance }
        }
    }

    /**
     * Retrieve a service instance for a specific protocol type.
     *
     * This method returns the service if registered, or throws an error if not found.
     *
     * - Parameter serviceType: The protocol type to retrieve
     * - Returns: The service instance
     * - Throws: ServiceLocatorError if service is not registered
     */
    func retrieve<T>(_ serviceType: T.Type) throws -> T {
        let key = String(describing: serviceType)

        return try queue.sync {
            guard let factory: () -> T = services[key] as? () -> T else {
                throw ServiceLocatorError.serviceNotFound(serviceType: String(describing: serviceType))
            }
            return factory()
        }
    }

    /**
     * Check if a service is registered for a specific protocol type.
     *
     * - Parameter serviceType: The protocol type to check
     * - Returns: True if service is registered, false otherwise
     */
    func isRegistered(_ serviceType: (some Any).Type) -> Bool {
        let key = String(describing: serviceType)
        return queue.sync {
            services[key] != nil
        }
    }

    /**
     * Clear all registered services.
     *
     * Useful for testing or when resetting the service locator.
     */
    func clear() {
        queue.async(flags: .barrier) {
            self.services.removeAll()
        }
    }
}

/**
 * Errors that can be thrown by ServiceLocator.
 */
enum ServiceLocatorError: Error, LocalizedError {
    case serviceNotFound(serviceType: String)

    var errorDescription: String? {
        switch self {
        case let .serviceNotFound(serviceType):
            "Service of type '\(serviceType)' is not registered in ServiceLocator"
        }
    }
}

// MARK: - Convenience Extensions

extension ServiceLocator {
    /**
     * Safely retrieve a service instance for a specific protocol type.
     *
     * This method returns the service if registered, or nil if not found.
     * Useful when you want to handle missing services gracefully.
     *
     * - Parameter serviceType: The protocol type to retrieve
     * - Returns: The service instance or nil if not registered
     */
    func safeRetrieve<T>(_ serviceType: T.Type) -> T? {
        do {
            return try retrieve(serviceType)
        } catch {
            return nil
        }
    }
}
