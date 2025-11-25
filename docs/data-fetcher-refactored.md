# DataFetcher Refactored - Configuration-Based Approach

## Overview

The DataFetcher has been refactored to use a **configuration-based approach** where all endpoint definitions, cache keys, and data type mappings are centralized in a separate configuration file. This makes the codebase more maintainable and scalable.

## New Architecture

```
┌─────────────────────────┐
│      ViewModel          │
└────────────┬────────────┘
             │
             ▼
    ┌────────────────┐
    │   DataType     │ ◄── Enum with config
    │   (enum)       │
    └────────┬───────┘
             │
             ▼
┌────────────────────────┐
│    DataFetcher         │ ◄── Generic fetch method
└────────────┬───────────┘
             │
    ┌────────┴────────┐
    ▼                 ▼
┌──────────┐   ┌──────────┐
│   API    │   │  Cache   │
└──────────┘   └──────────┘
```

## Key Files

### 1. DataFetcherConfig.swift
**Location**: `/Services/Core/DataFetcherConfig.swift`

Contains:
- `DataType` enum - Defines all available data types
- Endpoint configurations for each data type
- Cache key mappings
- Optional query parameters
- `CacheOperationsFactory` - Creates cache operations for each type

### 2. DataFetcher.swift (Refactored)
**Location**: `/Services/Core/DataFetcher.swift`

Now contains:
- Single generic `fetch<T>(_ dataType: DataType)` method
- Simplified logic using configuration
- Optional convenience methods for backward compatibility

## DataType Enum

The `DataType` enum is the heart of the new system:

```swift
enum DataType {
    // Activities
    case activities(userId: UUID)
    case activityTypes
    
    // Friends
    case friends(userId: UUID)
    case recommendedFriends(userId: UUID)
    case friendRequests(userId: UUID)
    case sentFriendRequests(userId: UUID)
    
    // Profile
    case profileStats(userId: UUID)
    case profileInterests(userId: UUID)
    case profileSocialMedia(userId: UUID)
    case profileActivities(userId: UUID)
}
```

Each case automatically provides:
- `endpoint` - API endpoint path
- `cacheKey` - Unique cache identifier
- `parameters` - Optional query parameters
- `displayName` - Human-readable name for logging

## Usage Examples

### Approach 1: Generic Method with DataType Enum (NEW)

This is the new, more flexible approach:

```swift
class MyViewModel: ObservableObject {
    @Published var activities: [FullFeedActivityDTO] = []
    private let dataFetcher = DataFetcher.shared
    
    func fetchData() async {
        // Use the generic fetch method with DataType enum
        let result: FetchResult<[FullFeedActivityDTO]> = await dataFetcher.fetch(
            .activities(userId: userId),
            cachePolicy: .cacheFirst(backgroundRefresh: true)
        )
        
        switch result {
        case .success(let data, let source):
            await MainActor.run {
                self.activities = data
            }
            print("Loaded from \(source == .cache ? "cache" : "API")")
            
        case .failure(let error):
            print("Error: \(error)")
        }
    }
}
```

### Approach 2: Convenience Methods (BACKWARD COMPATIBLE)

The convenience methods are still available and work exactly as before:

```swift
class MyViewModel: ObservableObject {
    @Published var activities: [FullFeedActivityDTO] = []
    private let dataFetcher = DataFetcher.shared
    
    func fetchData() async {
        // Use convenience method (internally calls generic fetch)
        let result = await dataFetcher.fetchActivities(
            userId: userId,
            cachePolicy: .cacheFirst(backgroundRefresh: true)
        )
        
        switch result {
        case .success(let data, _):
            await MainActor.run {
                self.activities = data
            }
        case .failure(let error):
            print("Error: \(error)")
        }
    }
}
```

### Approach 3: Dynamic Data Type Selection (NEW CAPABILITY)

You can now dynamically choose which data to fetch:

```swift
class MyViewModel: ObservableObject {
    private let dataFetcher = DataFetcher.shared
    
    func fetchUserData(for section: ProfileSection, userId: UUID) async {
        let dataType: DataType
        
        switch section {
        case .stats:
            dataType = .profileStats(userId: userId)
        case .interests:
            dataType = .profileInterests(userId: userId)
        case .socialMedia:
            dataType = .profileSocialMedia(userId: userId)
        case .activities:
            dataType = .profileActivities(userId: userId)
        }
        
        // Fetch the data dynamically based on section
        let result = await dataFetcher.fetch(dataType, cachePolicy: .cacheFirst())
        
        // Handle result...
    }
}
```

## Adding New Data Types

Adding a new data type is now incredibly simple - just update the configuration file:

### Step 1: Add to DataType Enum

```swift
enum DataType {
    // ... existing cases ...
    case userNotifications(userId: UUID)  // NEW
}
```

### Step 2: Add Configuration

```swift
extension DataType {
    var endpoint: String {
        switch self {
        // ... existing cases ...
        case .userNotifications(let userId):
            return "users/\(userId)/notifications"  // NEW
        }
    }
    
    var cacheKey: String {
        switch self {
        // ... existing cases ...
        case .userNotifications(let userId):
            return "notifications-\(userId)"  // NEW
        }
    }
    
    var displayName: String {
        switch self {
        // ... existing cases ...
        case .userNotifications:
            return "User Notifications"  // NEW
        }
    }
}
```

### Step 3: Add Cache Operations

```swift
struct CacheOperationsFactory {
    static func operations<T>(for dataType: DataType, appCache: AppCache) -> CacheOperations<T>? {
        switch dataType {
        // ... existing cases ...
        case .userNotifications(let userId):  // NEW
            if T.self == [NotificationDTO].self {
                return CacheOperations(
                    provider: { appCache.notifications[userId] as? T },
                    updater: { data in
                        if let notifications = data as? [NotificationDTO] {
                            appCache.updateNotifications(notifications, userId: userId)
                        }
                    }
                )
            }
        }
        return nil
    }
}
```

### Step 4: (Optional) Add Convenience Method

```swift
extension DataFetcher {
    func fetchUserNotifications(
        userId: UUID,
        cachePolicy: CachePolicy = .cacheFirst(backgroundRefresh: true)
    ) async -> FetchResult<[NotificationDTO]> {
        return await fetch(.userNotifications(userId: userId), cachePolicy: cachePolicy)
    }
}
```

That's it! The new data type is now fully integrated.

## Benefits of This Refactoring

### 1. **Centralized Configuration** ✅
All endpoints, cache keys, and parameters are in one place (`DataFetcherConfig.swift`)

**Before:**
```swift
// Scattered across DataFetcher
func fetchActivities(...) {
    let url = URL(string: APIService.baseURL + "users/\(userId)/activities")
    let cacheKey = "activities-\(userId)"
    // ... 20+ lines of logic
}

func fetchFriends(...) {
    let url = URL(string: APIService.baseURL + "users/friends/\(userId)")
    let cacheKey = "friends-\(userId)"
    // ... 20+ lines of logic
}
// Repeated for every data type...
```

**After:**
```swift
// In DataFetcherConfig.swift - one place
enum DataType {
    case activities(userId: UUID)
    case friends(userId: UUID)
    
    var endpoint: String {
        switch self {
        case .activities(let userId): return "users/\(userId)/activities"
        case .friends(let userId): return "users/friends/\(userId)"
        }
    }
}

// In DataFetcher.swift - single generic method
func fetch<T>(_ dataType: DataType) async -> FetchResult<T> {
    // Generic logic applies to all data types
}
```

### 2. **Easier to Maintain** ✅
- Want to change an endpoint? Update it in one place
- Want to change a cache key? Update it in one place
- No more hunting through code to find where things are defined

### 3. **More Scalable** ✅
Adding new data types requires minimal code:
- Add enum case
- Define endpoint/cache key
- Add cache operations
- Done!

No need to create entire new methods with duplicate logic.

### 4. **Type-Safe** ✅
The enum ensures you can't make typos in endpoint paths or cache keys

### 5. **Testable** ✅
Easy to test configurations independently:
```swift
func testEndpointGeneration() {
    let dataType = DataType.activities(userId: testUserId)
    XCTAssertEqual(dataType.endpoint, "users/\(testUserId)/activities")
    XCTAssertEqual(dataType.cacheKey, "activities-\(testUserId)")
}
```

### 6. **Backward Compatible** ✅
All existing convenience methods still work:
```swift
// Still works!
await dataFetcher.fetchActivities(userId: userId)
```

### 7. **Flexible** ✅
Can now dynamically choose what to fetch based on runtime conditions

## Configuration Details

### Endpoint Configuration

Endpoints are defined as computed properties on the `DataType` enum:

```swift
var endpoint: String {
    switch self {
    case .activities(let userId):
        return "users/\(userId)/activities"
    case .activityTypes:
        return "activity-types"
    // ...
    }
}
```

### Cache Key Configuration

Cache keys follow a consistent pattern:

```swift
var cacheKey: String {
    switch self {
    case .activities(let userId):
        return "activities-\(userId)"  // User-specific
    case .activityTypes:
        return "activityTypes"         // Global
    // ...
    }
}
```

### Query Parameters

Some endpoints require additional parameters:

```swift
var parameters: [String: String]? {
    switch self {
    case .profileActivities:
        // Profile activities need requesting user ID
        guard let requestingUserId = UserAuthViewModel.shared.spawnUser?.id else {
            return nil
        }
        return ["requestingUserId": requestingUserId.uuidString]
    default:
        return nil
    }
}
```

### Cache Operations

Cache operations are created by the factory based on the data type:

```swift
struct CacheOperationsFactory {
    static func operations<T>(for dataType: DataType, appCache: AppCache) -> CacheOperations<T>? {
        switch dataType {
        case .activities(let userId):
            if T.self == [FullFeedActivityDTO].self {
                return CacheOperations(
                    provider: { appCache.activities[userId] as? T },
                    updater: { data in
                        if let activities = data as? [FullFeedActivityDTO] {
                            appCache.updateActivitiesForUser(activities, userId: userId)
                        }
                    }
                )
            }
        // ...
        }
        return nil
    }
}
```

## Migration from Old DataFetcher

The migration is seamless! You have two options:

### Option 1: Keep Using Convenience Methods
No changes needed - everything works as before:
```swift
await dataFetcher.fetchActivities(userId: userId)
```

### Option 2: Switch to Generic Method
Update to use the new enum-based approach:

**Before:**
```swift
let result = await dataFetcher.fetchActivities(userId: userId)
```

**After:**
```swift
let result: FetchResult<[FullFeedActivityDTO]> = await dataFetcher.fetch(
    .activities(userId: userId)
)
```

## Best Practices

### 1. Use DataType Enum for Dynamic Fetching
When you need to fetch different data types based on conditions:
```swift
func fetchData(for tab: Tab) async {
    let dataType: DataType
    switch tab {
    case .activities: dataType = .activities(userId: userId)
    case .friends: dataType = .friends(userId: userId)
    case .stats: dataType = .profileStats(userId: userId)
    }
    
    let result = await dataFetcher.fetch(dataType)
}
```

### 2. Use Convenience Methods for Static Fetching
When you always fetch the same data type:
```swift
func fetchActivities() async {
    let result = await dataFetcher.fetchActivities(userId: userId)
}
```

### 3. Keep Configuration Organized
Group related data types together in the enum and switch statements

### 4. Document Custom Parameters
If a data type needs special parameters, document why:
```swift
case .profileActivities(let userId):
    // Requires requesting user ID for privacy checks
    return ["requestingUserId": requestingUserId.uuidString]
```

## Testing

### Testing Configurations

```swift
func testDataTypeConfiguration() {
    let userId = UUID()
    let dataType = DataType.activities(userId: userId)
    
    XCTAssertEqual(dataType.endpoint, "users/\(userId)/activities")
    XCTAssertEqual(dataType.cacheKey, "activities-\(userId)")
    XCTAssertEqual(dataType.displayName, "Activities")
    XCTAssertNil(dataType.parameters)
}
```

### Mocking DataFetcher

```swift
class MockDataFetcher: IDataFetcher {
    var mockResults: [String: Any] = [:]
    
    func fetch<T: Decodable>(
        _ dataType: DataType,
        cachePolicy: CachePolicy
    ) async -> FetchResult<T> {
        if let result = mockResults[dataType.cacheKey] as? T {
            return .success(result, source: .cache)
        }
        return .failure(DataFetcherError.noCachedData)
    }
}
```

## Summary

The refactored DataFetcher provides:

✅ **Centralized configuration** - All endpoints and cache keys in one place  
✅ **Easier maintenance** - Change once, apply everywhere  
✅ **Better scalability** - Add new data types with minimal code  
✅ **Type safety** - Enum prevents typos and errors  
✅ **Backward compatible** - Existing code works without changes  
✅ **More flexible** - Dynamic data type selection now possible  
✅ **Cleaner code** - ~400 lines reduced to ~200 lines  

The configuration-based approach makes the DataFetcher more maintainable and sets a strong foundation for future growth.


