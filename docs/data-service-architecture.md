# DataService Architecture - Unified Data Layer

## Overview

The new DataService architecture provides a unified, clean abstraction for all data operations in the app. It follows the **Repository Pattern**, separating ViewModels from the underlying APIService and AppCache implementations.

## Architecture Diagram

```
┌─────────────────────────────────────────┐
│           ViewModel Layer               │
│  (No direct APIService/AppCache deps)   │
└──────────────────┬──────────────────────┘
                   │
                   ▼
      ┌────────────────────────┐
      │     IDataService       │ ◄── Single interface for ViewModels
      │   (DataService impl)   │
      └────────┬──────┬────────┘
               │      │
       ┌───────┘      └───────┐
       ▼                      ▼
┌─────────────┐        ┌─────────────┐
│ IDataReader │        │ IDataWriter │
│ (DataReader)│        │(DataWriter) │
└──────┬──────┘        └──────┬──────┘
       │                      │
       ├──────────────────────┤
       ▼                      ▼
┌─────────────┐        ┌─────────────┐
│ APIService  │        │  AppCache   │
└─────────────┘        └─────────────┘
```

## Key Components

### 1. DataService (Facade)
- **Purpose**: Unified interface for all data operations
- **Location**: `Services/Core/DataService/DataService.swift`
- **Usage**: ViewModels should only depend on `IDataService`

### 2. DataReader
- **Purpose**: Handles read operations (GET)
- **Features**:
  - Cache-first strategy with optional background refresh
  - Configurable cache policies
  - Automatic cache updates after API fetches
- **Location**: `Services/Core/DataService/DataReader.swift`

### 3. DataWriter
- **Purpose**: Handles write operations (POST, PUT, PATCH, DELETE)
- **Features**:
  - Automatic cache invalidation after successful writes
  - Support for operations with and without response bodies
  - Configurable cache invalidation keys
- **Location**: `Services/Core/DataService/DataWriter.swift`

### 4. Supporting Types
- **DataServiceTypes.swift**: Common types (HTTPMethod, CachePolicy, DataSource, DataResult, errors)
- **WriteOperation.swift**: Configuration for write operations
- **DataTypeConfig.swift**: Configuration for data types and endpoints

## Migration Guide

### Before: Direct Dependencies

```swift
class MyViewModel: ObservableObject {
    private let apiService: IAPIService
    private let appCache: AppCache
    private let dataFetcher: DataFetcher
    
    init(apiService: IAPIService = APIService()) {
        self.apiService = apiService
        self.appCache = AppCache.shared
        self.dataFetcher = DataFetcher.shared
    }
    
    // Read operation
    func loadData() async {
        let result = await dataFetcher.fetchProfileStats(userId: userId)
        // Handle result...
    }
    
    // Write operation - direct APIService call
    func updateProfile(name: String) async {
        guard let url = URL(string: APIService.baseURL + "users/\(userId)") else { return }
        
        do {
            let updateDTO = UserUpdateDTO(name: name)
            let updatedUser: BaseUserDTO = try await apiService.patchData(
                from: url,
                with: updateDTO
            )
            // Update cache manually
            appCache.updateOtherProfile(userId, updatedUser)
        } catch {
            // Handle error...
        }
    }
}
```

### After: Using DataService Only

```swift
class MyViewModel: ObservableObject {
    private let dataService: IDataService
    
    init(dataService: IDataService = DataService.shared) {
        self.dataService = dataService
    }
    
    // Read operation
    func loadData() async {
        let result = await dataService.readProfileStats(userId: userId)
        
        switch result {
        case .success(let stats, let source):
            await MainActor.run {
                self.stats = stats
            }
            print("Loaded from \(source == .cache ? "cache" : "API")")
            
        case .failure(let error):
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // Write operation - clean and simple
    func updateProfile(name: String) async {
        let operation = WriteOperation<UserUpdateDTO>.patch(
            endpoint: "users/\(userId)",
            body: UserUpdateDTO(name: name),
            cacheInvalidationKeys: ["profileStats-\(userId)", "otherProfiles"]
        )
        
        let result: DataResult<BaseUserDTO> = await dataService.write(operation)
        
        switch result {
        case .success(let user, _):
            await MainActor.run {
                self.user = user
            }
            // Cache is automatically invalidated and updated
            
        case .failure(let error):
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
```

## Key Benefits

### 1. Single Responsibility
- **DataReader**: Only concerned with reading data
- **DataWriter**: Only concerned with writing data
- **DataService**: Provides unified interface

### 2. Dependency Inversion
- ViewModels depend on `IDataService` interface, not concrete implementations
- Easy to mock for testing
- Easy to swap implementations

### 3. Automatic Cache Management
- **Reads**: Automatic cache checks and updates
- **Writes**: Automatic cache invalidation after successful operations

### 4. Reduced Boilerplate
- No manual URL construction in ViewModels
- No manual cache updates after writes
- Consistent error handling

### 5. Testability
- ViewModels can be tested with mock DataService
- No need to mock both APIService AND AppCache

## HTTP Methods Support

### Read Operations (DataReader)
- **GET**: Standard read operation with caching

### Write Operations (DataWriter)
- **POST**: Create new resources
- **PUT**: Replace entire resources
- **PATCH**: Partial updates
- **DELETE**: Remove resources

## Cache Policies

### For Read Operations

```swift
// 1. Cache First (default) - check cache, use if available, optionally refresh
await dataService.read(dataType, cachePolicy: .cacheFirst(backgroundRefresh: true))

// 2. API Only - always fetch from API, bypass cache (but still update it)
await dataService.read(dataType, cachePolicy: .apiOnly)

// 3. Cache Only - only use cache, never fetch from API
await dataService.read(dataType, cachePolicy: .cacheOnly)
```

## Write Operations Examples

### POST - Create Activity

```swift
let createActivity = WriteOperation<CreateActivityDTO>.post(
    endpoint: "activities",
    body: CreateActivityDTO(...),
    cacheInvalidationKeys: ["activities-\(userId)"]
)

let result: DataResult<FullFeedActivityDTO> = await dataService.write(createActivity)
```

### PATCH - Update Profile

```swift
let updateProfile = WriteOperation<UserUpdateDTO>.patch(
    endpoint: "users/\(userId)",
    body: UserUpdateDTO(name: "New Name"),
    cacheInvalidationKeys: ["profileStats-\(userId)"]
)

let result: DataResult<BaseUserDTO> = await dataService.write(updateProfile)
```

### DELETE - Remove Friend

```swift
let removeFriend = WriteOperation<NoBody>.delete(
    endpoint: "friendships/\(friendshipId)",
    cacheInvalidationKeys: ["friends-\(userId)"]
)

let result = await dataService.writeWithoutResponse(removeFriend)
```

## Configuration-Based Operations

For common data types, use the `DataType` enum:

```swift
// Read operations
let result: DataResult<[FullFeedActivityDTO]> = await dataService.read(
    .activities(userId: userId)
)

let friendsResult: DataResult<[FullFriendUserDTO]> = await dataService.read(
    .friends(userId: userId),
    cachePolicy: .cacheFirst(backgroundRefresh: true)
)
```

## Testing

### Mock DataService

```swift
class MockDataService: IDataService {
    var mockReadResult: Any?
    var mockWriteResult: Any?
    
    func read<T: Decodable>(_ dataType: DataType, cachePolicy: CachePolicy) async -> DataResult<T> {
        if let result = mockReadResult as? T {
            return .success(result, source: .cache)
        }
        return .failure(DataServiceError.unsupportedDataType)
    }
    
    func write<RequestBody: Encodable, Response: Decodable>(
        _ operation: WriteOperation<RequestBody>,
        invalidateCache: Bool
    ) async -> DataResult<Response> {
        if let result = mockWriteResult as? Response {
            return .success(result, source: .api)
        }
        return .failure(DataServiceError.unsupportedDataType)
    }
    
    func writeWithoutResponse<RequestBody: Encodable>(
        _ operation: WriteOperation<RequestBody>,
        invalidateCache: Bool
    ) async -> DataResult<EmptyResponse> {
        return .success(EmptyResponse(), source: .api)
    }
}

// Usage in tests
let mockService = MockDataService()
mockService.mockReadResult = [FullFeedActivityDTO(...)]
let viewModel = MyViewModel(dataService: mockService)
```

## Backward Compatibility

The old `DataFetcher` API is still available through a compatibility layer:

```swift
// Old API (deprecated)
let dataFetcher = DataFetcher.shared
let result = await dataFetcher.fetchActivities(userId: userId)

// This is equivalent to:
let dataReader = DataReader.shared
let result = await dataReader.readActivities(userId: userId)
```

However, ViewModels should migrate to use `DataService` directly to benefit from the unified interface.

## Implementation Status

### ✅ Completed
- DataService protocol and implementation
- DataReader (renamed from DataFetcher)
- DataWriter for write operations
- HTTPMethod enum and supporting types
- WriteOperation configuration
- Backward compatibility layer

### 🔄 In Progress
- ViewModel migration (gradual rollout)
- Enhanced cache invalidation mechanisms
- Additional convenience methods

### 📋 Planned
- Automatic retry logic for failed operations
- Request queuing and deduplication
- Offline support with request queuing
- Analytics and logging integration

## Best Practices

### 1. Always Use DataService in ViewModels
```swift
// ✅ Good
private let dataService: IDataService

// ❌ Bad - direct dependencies
private let apiService: IAPIService
private let appCache: AppCache
```

### 2. Specify Cache Invalidation Keys
```swift
// ✅ Good - specific keys
cacheInvalidationKeys: ["friends-\(userId)", "friendRequests-\(userId)"]

// ❌ Bad - no cache invalidation
cacheInvalidationKeys: []
```

### 3. Use Configuration-Based Operations
```swift
// ✅ Good - use DataType enum
await dataService.read(.activities(userId: userId))

// ❌ Bad - manual URL construction (old way)
let url = URL(string: APIService.baseURL + "users/\(userId)/activities")
```

### 4. Handle Both Success and Failure Cases
```swift
// ✅ Good
switch result {
case .success(let data, let source):
    // Handle success
case .failure(let error):
    // Handle error
}

// ❌ Bad - ignoring errors
if case .success(let data, _) = result {
    // Only handle success
}
```

## Future Enhancements

### 1. Cache Invalidation Improvements
- Add `invalidateCacheKeys(_ keys: [String])` method to AppCache
- Selective cache refresh after writes
- Cache versioning and migration

### 2. Request Optimization
- Automatic request deduplication
- Request cancellation support
- Priority-based request queuing

### 3. Offline Support
- Queue write operations when offline
- Sync when connection restored
- Conflict resolution strategies

### 4. Analytics
- Track cache hit rates
- Monitor API performance
- Log operation timings

## Migration Checklist

For each ViewModel:

- [ ] Replace `IAPIService` dependency with `IDataService`
- [ ] Replace `DataFetcher` dependency with `IDataService`
- [ ] Remove direct `AppCache` dependencies
- [ ] Replace `fetch*` calls with `read*` calls
- [ ] Replace direct API calls with `write` or `writeWithoutResponse`
- [ ] Add cache invalidation keys to write operations
- [ ] Update tests to use mock DataService
- [ ] Remove manual cache update logic

## Summary

The new DataService architecture provides:
- ✅ **Cleaner ViewModels**: Single dependency instead of multiple
- ✅ **Better Testing**: Easy to mock with one interface
- ✅ **Automatic Caching**: No manual cache management
- ✅ **Consistent Patterns**: Same approach for all data operations
- ✅ **Type Safety**: Configuration-based operations with compile-time checking
- ✅ **Scalability**: Easy to add new data types and operations

This architecture follows SOLID principles and makes the codebase more maintainable and testable.

