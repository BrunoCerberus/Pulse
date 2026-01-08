# Generate Service

Creates a Service protocol and Live implementation.

## Usage

```
/pulse:gen-service <FeatureName>
```

## Arguments

- `FeatureName`: PascalCase name (e.g., `Profile`, `Notifications`)

## Output Locations

```
Pulse/<FeatureName>/API/<FeatureName>Service.swift      # Protocol
Pulse/<FeatureName>/API/Live<FeatureName>Service.swift  # Implementation
Pulse/Configs/Mocks/Mock<FeatureName>Service.swift      # Mock (optional)
```

## Protocol Template

```swift
import Combine
import Foundation

protocol <FeatureName>Service {
    /// Fetches a paginated list of entities
    func fetch<Entity>s(page: Int) -> AnyPublisher<[<Entity>], Error>

    /// Fetches a single entity by ID
    func fetch<Entity>(id: String) -> AnyPublisher<<Entity>, Error>

    /// Creates a new entity
    func create<Entity>(_ entity: <Entity>) -> AnyPublisher<<Entity>, Error>

    /// Updates an existing entity
    func update<Entity>(_ entity: <Entity>) -> AnyPublisher<<Entity>, Error>

    /// Deletes an entity by ID
    func delete<Entity>(id: String) -> AnyPublisher<Void, Error>

    /// Searches entities with a query
    func search(query: String, page: Int) -> AnyPublisher<[<Entity>], Error>
}
```

## Live Implementation Template

```swift
import Combine
import Foundation

final class Live<FeatureName>Service: APIRequest, <FeatureName>Service {

    // MARK: - Fetch List

    func fetch<Entity>s(page: Int) -> AnyPublisher<[<Entity>], Error> {
        fetchRequest(
            target: <FeatureName>API.list(page: page, pageSize: 20),
            dataType: <Entity>ListResponse.self
        )
        .map { response in
            response.results.compactMap { $0.toDomain() }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Fetch Single

    func fetch<Entity>(id: String) -> AnyPublisher<<Entity>, Error> {
        fetchRequest(
            target: <FeatureName>API.detail(id: id),
            dataType: <Entity>Response.self
        )
        .map { $0.toDomain() }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Create

    func create<Entity>(_ entity: <Entity>) -> AnyPublisher<<Entity>, Error> {
        fetchRequest(
            target: <FeatureName>API.create(entity: entity),
            dataType: <Entity>Response.self
        )
        .map { $0.toDomain() }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Update

    func update<Entity>(_ entity: <Entity>) -> AnyPublisher<<Entity>, Error> {
        fetchRequest(
            target: <FeatureName>API.update(entity: entity),
            dataType: <Entity>Response.self
        )
        .map { $0.toDomain() }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Delete

    func delete<Entity>(id: String) -> AnyPublisher<Void, Error> {
        fetchRequest(
            target: <FeatureName>API.delete(id: id),
            dataType: EmptyResponse.self
        )
        .map { _ in () }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }

    // MARK: - Search

    func search(query: String, page: Int) -> AnyPublisher<[<Entity>], Error> {
        fetchRequest(
            target: <FeatureName>API.search(query: query, page: page, pageSize: 20),
            dataType: <Entity>ListResponse.self
        )
        .map { response in
            response.results.compactMap { $0.toDomain() }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
```

## Mock Implementation Template

```swift
import Combine
import Foundation

final class Mock<FeatureName>Service: <FeatureName>Service {

    // MARK: - Configurable Responses

    var mock<Entity>s: [<Entity>] = []
    var mockError: Error?
    var delay: TimeInterval = 0

    // MARK: - Call Tracking

    private(set) var fetch<Entity>sCallCount = 0
    private(set) var lastFetchPage: Int?

    // MARK: - <FeatureName>Service

    func fetch<Entity>s(page: Int) -> AnyPublisher<[<Entity>], Error> {
        fetch<Entity>sCallCount += 1
        lastFetchPage = page

        if let error = mockError {
            return Fail(error: error)
                .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        }

        return Just(mock<Entity>s)
            .setFailureType(to: Error.self)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetch<Entity>(id: String) -> AnyPublisher<<Entity>, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }

        guard let entity = mock<Entity>s.first(where: { $0.id == id }) else {
            return Fail(error: ServiceError.notFound).eraseToAnyPublisher()
        }

        return Just(entity)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func create<Entity>(_ entity: <Entity>) -> AnyPublisher<<Entity>, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return Just(entity)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func update<Entity>(_ entity: <Entity>) -> AnyPublisher<<Entity>, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return Just(entity)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func delete<Entity>(id: String) -> AnyPublisher<Void, Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func search(query: String, page: Int) -> AnyPublisher<[<Entity>], Error> {
        if let error = mockError {
            return Fail(error: error).eraseToAnyPublisher()
        }

        let filtered = mock<Entity>s.filter {
            $0.title.localizedCaseInsensitiveContains(query)
        }

        return Just(filtered)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Service Error

enum ServiceError: Error, LocalizedError {
    case notFound
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Resource not found"
        case .unauthorized:
            return "Unauthorized access"
        case let .serverError(message):
            return message
        }
    }
}
```

## API Endpoint Template

```swift
import EntropyCore

enum <FeatureName>API: APIFetcher {
    case list(page: Int, pageSize: Int)
    case detail(id: String)
    case create(entity: <Entity>)
    case update(entity: <Entity>)
    case delete(id: String)
    case search(query: String, page: Int, pageSize: Int)

    var path: String {
        switch self {
        case .list, .create:
            return "/api/<entities>"
        case let .detail(id), let .delete(id):
            return "/api/<entities>/\(id)"
        case let .update(entity):
            return "/api/<entities>/\(entity.id)"
        case .search:
            return "/api/<entities>/search"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .list, .detail, .search:
            return .GET
        case .create:
            return .POST
        case .update:
            return .PUT
        case .delete:
            return .DELETE
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case let .list(page, pageSize):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "pageSize", value: "\(pageSize)")
            ]
        case let .search(query, page, pageSize):
            return [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "pageSize", value: "\(pageSize)")
            ]
        default:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case let .create(entity), let .update(entity):
            return try? JSONEncoder().encode(entity)
        default:
            return nil
        }
    }
}
```

## Registration

Add to `PulseSceneDelegate.swift`:

```swift
serviceLocator.register(<FeatureName>Service.self, instance: Live<FeatureName>Service())
```

## Key Patterns

1. **Protocol-first design** - Define interface before implementation
2. **Return `AnyPublisher`** - Uniform reactive interface
3. **Use `.receive(on: DispatchQueue.main)`** - Ensure main thread delivery
4. **Transform responses** - Map API models to domain models
5. **Mock supports configuration** - `mockEntities`, `mockError`, `delay`

## Instructions

1. Ask what **operations** the service needs (CRUD, search, etc.)
2. Ask about **API endpoints** and response formats
3. Create the protocol with appropriate methods
4. Create Live implementation with API calls
5. **Optionally** create Mock for testing
6. **Remind to register** in `PulseSceneDelegate.swift`
