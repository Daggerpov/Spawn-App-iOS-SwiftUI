# DataService Migration Guide

## Overview

This guide provides step-by-step instructions for migrating ViewModels from the old architecture (direct APIService/AppCache dependencies) to the new DataService architecture.

## Quick Reference

### Old vs New API

| Operation | Old API | New API |
|-----------|---------|---------|
| **Initialization** | `DataFetcher.shared`, `APIService()`, `AppCache.shared` | `DataService.shared` |
| **Read data** | `dataFetcher.fetchActivities(...)` | `dataService.readActivities(...)` or `dataService.read(.activities(...))` |
| **POST** | `apiService.sendData(dto, to: url, ...)` | `dataService.write(WriteOperation.post(...))` |
| **PUT** | `apiService.updateData(dto, to: url, ...)` | `dataService.write(WriteOperation.put(...))` |
| **PATCH** | `apiService.patchData(from: url, with: dto)` | `dataService.write(WriteOperation.patch(...))` |
| **DELETE** | `apiService.deleteData(from: url, ...)` | `dataService.writeWithoutResponse(WriteOperation.delete(...))` |
| **Cache update** | `appCache.updateActivities(...)` | Automatic |

## Migration Steps

### Step 1: Update Dependencies

#### Before:
```swift
class ProfileViewModel: ObservableObject {
    private let apiService: IAPIService
    private let appCache: AppCache
    private let dataFetcher: DataFetcher
    
    init(apiService: IAPIService? = nil) {
        self.dataFetcher = DataFetcher.shared
        self.appCache = AppCache.shared
        
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            self.apiService = MockAPIService.isMocking 
                ? MockAPIService(userId: userId) 
                : APIService()
        }
    }
}
```

#### After:
```swift
class ProfileViewModel: ObservableObject {
    private let dataService: IDataService
    
    init(dataService: IDataService = DataService.shared) {
        self.dataService = dataService
    }
}
```

### Step 2: Migrate Read Operations

#### Before:
```swift
func fetchUserStats(userId: UUID) async {
    let result = await dataFetcher.fetchProfileStats(
        userId: userId,
        cachePolicy: .cacheFirst(backgroundRefresh: true)
    )
    
    switch result {
    case .success(let stats, let source):
        await MainActor.run {
            self.userStats = stats
            self.isLoadingStats = false
        }
        print("✅ Loaded stats from \(source == .cache ? "cache" : "API")")
        
    case .failure(let error):
        await MainActor.run {
            self.errorMessage = ErrorFormattingService.shared.formatError(error)
            self.isLoadingStats = false
        }
    }
}
```

#### After:
```swift
func fetchUserStats(userId: UUID) async {
    // Option 1: Use convenience method
    let result = await dataService.readProfileStats(
        userId: userId,
        cachePolicy: .cacheFirst(backgroundRefresh: true)
    )
    
    // Option 2: Use generic read with DataType
    // let result: DataResult<UserStatsDTO> = await dataService.read(
    //     .profileStats(userId: userId),
    //     cachePolicy: .cacheFirst(backgroundRefresh: true)
    // )
    
    switch result {
    case .success(let stats, let source):
        await MainActor.run {
            self.userStats = stats
            self.isLoadingStats = false
        }
        print("✅ Loaded stats from \(source == .cache ? "cache" : "API")")
        
    case .failure(let error):
        await MainActor.run {
            self.errorMessage = ErrorFormattingService.shared.formatError(error)
            self.isLoadingStats = false
        }
    }
}
```

### Step 3: Migrate Write Operations (POST)

#### Before:
```swift
func createActivity(activityDTO: CreateActivityDTO) async {
    guard let url = URL(string: APIService.baseURL + "activities") else {
        print("❌ Invalid URL")
        return
    }
    
    do {
        let createdActivity: FullFeedActivityDTO = try await apiService.sendData(
            activityDTO,
            to: url,
            parameters: nil
        )
        
        // Manually update cache
        await MainActor.run {
            appCache.addOrUpdateActivity(createdActivity)
            NotificationCenter.default.post(name: .activityCreated, object: createdActivity)
        }
    } catch {
        print("❌ Error creating activity: \(error)")
    }
}
```

#### After:
```swift
func createActivity(activityDTO: CreateActivityDTO) async {
    let operation = WriteOperation<CreateActivityDTO>.post(
        endpoint: "activities",
        body: activityDTO,
        parameters: nil,
        cacheInvalidationKeys: ["activities-\(userId)"]
    )
    
    let result: DataResult<FullFeedActivityDTO> = await dataService.write(operation)
    
    switch result {
    case .success(let createdActivity, _):
        // Cache is automatically invalidated
        await MainActor.run {
            NotificationCenter.default.post(name: .activityCreated, object: createdActivity)
        }
        
    case .failure(let error):
        print("❌ Error creating activity: \(error)")
    }
}
```

### Step 4: Migrate Write Operations (PATCH)

#### Before:
```swift
func updateProfile(name: String, username: String) async {
    guard let userId = spawnUser?.id else { return }
    guard let url = URL(string: APIService.baseURL + "users/update/\(userId)") else {
        return
    }
    
    do {
        let updateDTO = UserUpdateDTO(username: username, name: name)
        
        let updatedUser: BaseUserDTO = try await apiService.patchData(
            from: url,
            with: updateDTO
        )
        
        await MainActor.run {
            self.spawnUser = updatedUser
            appCache.updateOtherProfile(userId, updatedUser)
            
            NotificationCenter.default.post(
                name: .profileUpdated,
                object: nil,
                userInfo: ["updatedUser": updatedUser]
            )
        }
    } catch {
        print("Error updating profile: \(error.localizedDescription)")
    }
}
```

#### After:
```swift
func updateProfile(name: String, username: String) async {
    guard let userId = spawnUser?.id else { return }
    
    let updateDTO = UserUpdateDTO(username: username, name: name)
    let operation = WriteOperation<UserUpdateDTO>.patch(
        endpoint: "users/update/\(userId)",
        body: updateDTO,
        cacheInvalidationKeys: [
            "profileStats-\(userId)",
            "otherProfiles-\(userId)"
        ]
    )
    
    let result: DataResult<BaseUserDTO> = await dataService.write(operation)
    
    switch result {
    case .success(let updatedUser, _):
        await MainActor.run {
            self.spawnUser = updatedUser
            // Cache is automatically updated
            
            NotificationCenter.default.post(
                name: .profileUpdated,
                object: nil,
                userInfo: ["updatedUser": updatedUser]
            )
        }
        
    case .failure(let error):
        print("Error updating profile: \(error.localizedDescription)")
    }
}
```

### Step 5: Migrate Write Operations (DELETE)

#### Before:
```swift
func deleteFriend(friendshipId: UUID) async {
    guard let url = URL(string: APIService.baseURL + "friendships/\(friendshipId)") else {
        return
    }
    
    do {
        try await apiService.deleteData(from: url, parameters: nil, object: nil as EmptyObject?)
        
        await MainActor.run {
            // Manually refresh cache
            Task {
                await appCache.refreshFriends()
            }
        }
    } catch {
        print("Error deleting friend: \(error)")
    }
}
```

#### After:
```swift
func deleteFriend(friendshipId: UUID) async {
    guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
    
    let operation = WriteOperation<NoBody>.delete(
        endpoint: "friendships/\(friendshipId)",
        cacheInvalidationKeys: [
            "friends-\(userId)",
            "recommendedFriends-\(userId)"
        ]
    )
    
    let result = await dataService.writeWithoutResponse(operation)
    
    switch result {
    case .success:
        // Cache is automatically invalidated
        print("✅ Friend deleted successfully")
        
    case .failure(let error):
        print("❌ Error deleting friend: \(error)")
    }
}
```

### Step 6: Remove Manual Cache Updates

#### Before:
```swift
func createActivity() async {
    // ... API call ...
    
    // Manual cache update
    await MainActor.run {
        appCache.addOrUpdateActivity(newActivity)
        appCache.updateActivitiesForUser([...], userId: userId)
    }
}
```

#### After:
```swift
func createActivity() async {
    // ... DataService write call ...
    
    // Cache is automatically invalidated and will refresh on next read
    // No manual cache updates needed!
}
```

## Common Patterns

### Pattern 1: Read with Custom Cache Policy

```swift
// Read from API only, bypassing cache
let result: DataResult<[FullFeedActivityDTO]> = await dataService.read(
    .activities(userId: userId),
    cachePolicy: .apiOnly
)

// Read from cache only, never hitting API
let cachedResult: DataResult<[FullFriendUserDTO]> = await dataService.read(
    .friends(userId: userId),
    cachePolicy: .cacheOnly
)
```

### Pattern 2: Write with Multiple Cache Invalidations

```swift
let operation = WriteOperation<ActivityUpdateDTO>.patch(
    endpoint: "activities/\(activityId)/partial",
    body: updateDTO,
    cacheInvalidationKeys: [
        "activities-\(userId)",           // User's activities
        "profileActivities-\(userId)",    // Profile activities
        "activityTypes"                   // Activity types cache
    ]
)
```

### Pattern 3: Write Without Response Body

```swift
// For DELETE operations or POST operations that return 204 No Content
let operation = WriteOperation<NoBody>.delete(
    endpoint: "friend-requests/\(requestId)",
    cacheInvalidationKeys: ["friendRequests-\(userId)"]
)

let result = await dataService.writeWithoutResponse(operation)
```

### Pattern 4: Write with Query Parameters

```swift
let operation = WriteOperation<CreateActivityDTO>.post(
    endpoint: "activities",
    body: activityDTO,
    parameters: ["includeDetails": "true", "notifyFriends": "false"],
    cacheInvalidationKeys: ["activities-\(userId)"]
)
```

## Testing Changes

### Before:
```swift
func testFetchActivities() async {
    let mockAPI = MockAPIService(userId: testUserId)
    let viewModel = FeedViewModel(apiService: mockAPI, userId: testUserId)
    
    await viewModel.fetchActivitiesForUser()
    
    XCTAssertEqual(viewModel.activities.count, 5)
}
```

### After:
```swift
class MockDataService: IDataService {
    var mockActivities: [FullFeedActivityDTO] = []
    
    func read<T: Decodable>(
        _ dataType: DataType,
        cachePolicy: CachePolicy
    ) async -> DataResult<T> {
        if T.self == [FullFeedActivityDTO].self {
            return .success(mockActivities as! T, source: .cache)
        }
        return .failure(DataServiceError.unsupportedDataType)
    }
    
    // ... implement other methods ...
}

func testFetchActivities() async {
    let mockService = MockDataService()
    mockService.mockActivities = [/* test data */]
    
    let viewModel = FeedViewModel(dataService: mockService, userId: testUserId)
    
    await viewModel.fetchActivitiesForUser()
    
    XCTAssertEqual(viewModel.activities.count, 5)
}
```

## Migration Checklist

For each ViewModel, complete these steps:

### Dependencies
- [ ] Remove `private let apiService: IAPIService`
- [ ] Remove `private let appCache: AppCache`
- [ ] Remove `private let dataFetcher: DataFetcher`
- [ ] Add `private let dataService: IDataService`
- [ ] Update initializer to accept `IDataService`

### Read Operations
- [ ] Replace all `dataFetcher.fetch*()` calls with `dataService.read*()`
- [ ] Update result type from `FetchResult<T>` to `DataResult<T>`
- [ ] Remove any manual cache checks before API calls

### Write Operations
- [ ] Replace all `apiService.sendData()` calls with `dataService.write()`
- [ ] Replace all `apiService.updateData()` calls with `dataService.write()`
- [ ] Replace all `apiService.patchData()` calls with `dataService.write()`
- [ ] Replace all `apiService.deleteData()` calls with `dataService.writeWithoutResponse()`
- [ ] Add appropriate cache invalidation keys to each write operation

### Cache Management
- [ ] Remove all manual `appCache.update*()` calls after write operations
- [ ] Remove all manual cache refresh calls
- [ ] Let DataService handle cache invalidation automatically

### Error Handling
- [ ] Update error handling to use `DataServiceError` types
- [ ] Ensure both success and failure cases are handled

### Testing
- [ ] Update test mocks to implement `IDataService`
- [ ] Update test cases to use new API
- [ ] Add tests for cache invalidation behavior

## Common Migration Issues

### Issue 1: URL Construction
**Problem**: Old code manually constructs URLs
```swift
// ❌ Old way
guard let url = URL(string: APIService.baseURL + "users/\(userId)/activities") else { return }
```

**Solution**: Use endpoint strings directly
```swift
// ✅ New way
let operation = WriteOperation<CreateActivityDTO>.post(
    endpoint: "users/\(userId)/activities",  // Just the path
    body: activityDTO
)
```

### Issue 2: Optional Response Bodies
**Problem**: Some POST/PUT operations don't return a response body
```swift
// ❌ Old way - returns nil
let result: BaseUserDTO? = try await apiService.sendData(dto, to: url, parameters: nil)
```

**Solution**: Use `writeWithoutResponse` for operations without response
```swift
// ✅ New way
let result = await dataService.writeWithoutResponse(operation)
```

### Issue 3: Cache Invalidation Keys
**Problem**: Not sure which cache keys to invalidate

**Solution**: Check `DataTypeConfig.swift` for cache key patterns:
```swift
// For activities: "activities-{userId}"
// For friends: "friends-{userId}"
// For profile: "profileStats-{userId}", "profileInterests-{userId}", etc.
```

### Issue 4: Mock APIService in Tests
**Problem**: Tests use MockAPIService directly

**Solution**: Create a MockDataService that implements IDataService
```swift
class MockDataService: IDataService {
    var mockReadResults: [String: Any] = [:]
    var mockWriteResults: [String: Any] = [:]
    
    // Implement protocol methods...
}
```

## Priority Order for Migration

Migrate ViewModels in this order:

### High Priority (Core functionality)
1. ✅ FeedViewModel
2. ✅ ProfileViewModel
3. ✅ FriendRequestsViewModel
4. ✅ ActivityTypeViewModel

### Medium Priority (Secondary features)
5. ActivityCreationViewModel
6. ActivityDescriptionViewModel
7. FriendsTabViewModel
8. UserAuthViewModel (partial migration)

### Low Priority (Specialized features)
9. FeedbackViewModel
10. NotificationViewModel
11. Other specialized ViewModels

## Support

If you encounter issues during migration:

1. Check the [DataService Architecture](./data-service-architecture.md) document
2. Look at migrated ViewModels for examples (FeedViewModel, ProfileViewModel)
3. Review the compatibility layer in `DataFetcher+Compatibility.swift`
4. Test incrementally - migrate one method at a time

## Summary

Key changes:
- ✅ **Single dependency**: `IDataService` instead of multiple
- ✅ **Automatic caching**: No manual cache updates
- ✅ **Cleaner code**: Less boilerplate
- ✅ **Better testing**: Easier to mock
- ✅ **Type safety**: Configuration-based operations

The migration provides immediate benefits in code cleanliness and maintainability while setting up the codebase for future enhancements like offline support and request optimization.

