# DataFetcher Implementation Guide

## Overview

The `DataFetcher` service is a middle-man layer between ViewModels and the APIService/AppCache that standardizes data fetching patterns across the app. It reduces code duplication, simplifies dependencies, and provides consistent caching behavior.

## Architecture

```
┌─────────────┐
│  ViewModel  │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│ DataFetcher │ ◄── Middle-man service
└─────┬───────┘
      │
      ├─────────────┐
      ▼             ▼
┌─────────────┐ ┌─────────────┐
│ APIService  │ │  AppCache   │
└─────────────┘ └─────────────┘
```

## Key Benefits

### 1. Reduced Code Duplication
Before DataFetcher, every ViewModel had to implement the same cache-first, then API pattern:
```swift
// BEFORE: Repetitive code in every ViewModel
func fetchData() async {
    // Check cache first
    if let cached = appCache.getData() {
        self.data = cached
        // Maybe refresh in background
        Task { await fetchFromAPI() }
        return
    }
    // Fetch from API
    await fetchFromAPI()
}
```

After DataFetcher, ViewModels simply call the service:
```swift
// AFTER: Clean and simple
func fetchData() async {
    let result = await dataFetcher.fetchData(
        userId: userId,
        cachePolicy: .cacheFirst(backgroundRefresh: true)
    )
    // Handle result
}
```

### 2. Simplified Dependencies
- **Before**: ViewModels depended on both `APIService` and `AppCache`
- **After**: ViewModels only depend on `DataFetcher` (plus `APIService` for write operations)

### 3. Consistent Caching Behavior
All data fetching follows the same patterns with configurable cache policies.

## Cache Policies

DataFetcher supports three cache policies:

### 1. Cache First (with optional background refresh)
```swift
.cacheFirst(backgroundRefresh: true)
```
- Checks cache first
- If data exists in cache, returns it immediately
- Optionally fetches fresh data in background to keep cache updated
- **Use when**: You want instant UI updates with eventual consistency

### 2. API Only
```swift
.apiOnly
```
- Always fetches from API, bypassing cache
- Still updates cache after successful fetch
- **Use when**: You need guaranteed fresh data (e.g., force refresh)

### 3. Cache Only
```swift
.cacheOnly
```
- Only uses cache, never fetches from API
- **Use when**: You want offline-first behavior or already have data

## Core API

### Protocol Definition

```swift
protocol IDataFetcher {
    func fetch<T: Decodable>(
        cacheKey: String,
        cachePolicy: CachePolicy,
        cacheProvider: @escaping () -> T?,
        apiProvider: @escaping () async throws -> T,
        cacheUpdater: @escaping (T) -> Void
    ) async -> FetchResult<T>
    
    func fetchUserData<T: Decodable>(
        userId: UUID,
        dataType: String,
        cachePolicy: CachePolicy,
        cacheProvider: @escaping (UUID) -> T?,
        apiProvider: @escaping (UUID) async throws -> T,
        cacheUpdater: @escaping (UUID, T) -> Void
    ) async -> FetchResult<T>
}
```

### Fetch Result

```swift
enum FetchResult<T> {
    case success(T, source: DataSource)
    case failure(Error)
    
    enum DataSource {
        case cache
        case api
    }
}
```

## Built-in Specialized Methods

DataFetcher provides convenience methods for common data types:

### Activities
```swift
// Fetch activities for a user
await dataFetcher.fetchActivities(
    userId: userId,
    cachePolicy: .cacheFirst(backgroundRefresh: true)
)

// Fetch activity types
await dataFetcher.fetchActivityTypes(
    cachePolicy: .cacheFirst(backgroundRefresh: true)
)
```

### Friends
```swift
// Fetch friends
await dataFetcher.fetchFriends(
    userId: userId,
    cachePolicy: .cacheFirst(backgroundRefresh: true)
)

// Fetch recommended friends
await dataFetcher.fetchRecommendedFriends(
    userId: userId,
    cachePolicy: .cacheFirst(backgroundRefresh: true)
)

// Fetch friend requests
await dataFetcher.fetchFriendRequests(
    userId: userId,
    cachePolicy: .cacheFirst(backgroundRefresh: true)
)

// Fetch sent friend requests
await dataFetcher.fetchSentFriendRequests(
    userId: userId,
    cachePolicy: .cacheFirst(backgroundRefresh: true)
)
```

### Profile
```swift
// Fetch profile stats
await dataFetcher.fetchProfileStats(
    userId: userId,
    cachePolicy: .cacheFirst(backgroundRefresh: true)
)

// Fetch profile interests
await dataFetcher.fetchProfileInterests(
    userId: userId,
    cachePolicy: .cacheFirst(backgroundRefresh: true)
)

// Fetch profile social media
await dataFetcher.fetchProfileSocialMedia(
    userId: userId,
    cachePolicy: .cacheFirst(backgroundRefresh: true)
)

// Fetch profile activities
await dataFetcher.fetchProfileActivities(
    userId: userId,
    cachePolicy: .cacheFirst(backgroundRefresh: true)
)
```

## Usage Examples

### Example 1: Basic Usage in ViewModel

```swift
class MyViewModel: ObservableObject {
    @Published var data: [SomeDTO] = []
    
    private let dataFetcher: DataFetcher
    private let userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
        self.dataFetcher = DataFetcher.shared
    }
    
    func fetchData() async {
        let result = await dataFetcher.fetchFriends(
            userId: userId,
            cachePolicy: .cacheFirst(backgroundRefresh: true)
        )
        
        switch result {
        case .success(let friends, let source):
            await MainActor.run {
                self.data = friends
            }
            print("Loaded \(friends.count) friends from \(source == .cache ? "cache" : "API")")
            
        case .failure(let error):
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
```

### Example 2: Force Refresh

```swift
func forceRefresh() async {
    // Bypass cache and fetch fresh data
    let result = await dataFetcher.fetchFriends(
        userId: userId,
        cachePolicy: .apiOnly
    )
    
    // Handle result...
}
```

### Example 3: Offline-First Approach

```swift
func loadOfflineData() async {
    // Only use cache, don't make API calls
    let result = await dataFetcher.fetchFriends(
        userId: userId,
        cachePolicy: .cacheOnly
    )
    
    switch result {
    case .success(let friends, _):
        // Use cached data
        await MainActor.run {
            self.data = friends
        }
        
    case .failure:
        // No cached data available
        print("No offline data available")
    }
}
```

### Example 4: Custom Generic Fetch

If you need to fetch data that doesn't have a specialized method:

```swift
let result = await dataFetcher.fetch(
    cacheKey: "custom-key",
    cachePolicy: .cacheFirst(backgroundRefresh: true),
    cacheProvider: {
        // Return cached data or nil
        return self.appCache.customData
    },
    apiProvider: {
        // Fetch from API
        let url = URL(string: "\(APIService.baseURL)custom-endpoint")!
        return try await self.apiService.fetchData(from: url, parameters: nil)
    },
    cacheUpdater: { data in
        // Update cache
        self.appCache.updateCustomData(data)
    }
)
```

## Migration Guide

### Step 1: Update ViewModel Dependencies

**Before:**
```swift
class MyViewModel: ObservableObject {
    var apiService: IAPIService
    private var appCache: AppCache
    
    init(apiService: IAPIService) {
        self.apiService = apiService
        self.appCache = AppCache.shared
    }
}
```

**After:**
```swift
class MyViewModel: ObservableObject {
    private var dataFetcher: DataFetcher
    private var apiService: IAPIService  // Keep for write operations only
    private var appCache: AppCache  // Keep for cache subscriptions only
    
    init(apiService: IAPIService) {
        self.apiService = apiService
        self.dataFetcher = DataFetcher.shared
        self.appCache = AppCache.shared
    }
}
```

### Step 2: Replace Fetch Methods

**Before:**
```swift
func fetchActivities() async {
    // Check cache first
    let cachedActivities = appCache.getCurrentUserActivities()
    if !cachedActivities.isEmpty {
        await MainActor.run {
            self.activities = cachedActivities
        }
        // Refresh in background
        Task {
            await fetchFromAPI()
        }
        return
    }
    
    // Fetch from API
    await fetchFromAPI()
}

private func fetchFromAPI() async {
    guard let url = URL(string: APIService.baseURL + "activities/\(userId)") else {
        return
    }
    
    do {
        let activities: [ActivityDTO] = try await apiService.fetchData(from: url, parameters: nil)
        await MainActor.run {
            self.activities = activities
            self.appCache.updateActivitiesForUser(activities, userId: userId)
        }
    } catch {
        print("Error: \(error)")
    }
}
```

**After:**
```swift
func fetchActivities() async {
    let result = await dataFetcher.fetchActivities(
        userId: userId,
        cachePolicy: .cacheFirst(backgroundRefresh: true)
    )
    
    switch result {
    case .success(let activities, let source):
        await MainActor.run {
            self.activities = activities
        }
        print("Loaded \(activities.count) activities from \(source == .cache ? "cache" : "API")")
        
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## Best Practices

### 1. Choose the Right Cache Policy

- **Most common**: Use `.cacheFirst(backgroundRefresh: true)` for instant UI updates with eventual consistency
- **Force refresh**: Use `.apiOnly` for user-initiated refreshes (pull-to-refresh)
- **Offline mode**: Use `.cacheOnly` when you know you're offline or want to avoid API calls

### 2. Handle Both Success and Failure Cases

Always handle both cases in the switch statement:
```swift
switch result {
case .success(let data, let source):
    // Update UI with data
    // Use source to know if it's cached or fresh
case .failure(let error):
    // Show error to user
    // Fall back to cached data if appropriate
}
```

### 3. Keep APIService for Write Operations

DataFetcher is for **read operations** only. Keep `apiService` in your ViewModel for:
- Creating data (POST)
- Updating data (PUT/PATCH)
- Deleting data (DELETE)

```swift
// ❌ Don't use DataFetcher for writes
// ✅ Use APIService directly
func createActivity(activity: ActivityDTO) async {
    let url = URL(string: "\(APIService.baseURL)activities")!
    try await apiService.sendData(activity, to: url, parameters: nil)
}
```

### 4. Keep Cache Subscriptions

For reactive updates, keep your cache subscriptions:
```swift
init() {
    self.dataFetcher = DataFetcher.shared
    
    // Keep cache subscriptions for real-time updates
    appCache.activitiesPublisher
        .sink { [weak self] activities in
            self?.handleCacheUpdate(activities)
        }
        .store(in: &cancellables)
}
```

### 5. Log Data Source for Debugging

Use the `source` value to understand where data came from:
```swift
case .success(let data, let source):
    print("✅ Loaded from \(source == .cache ? "cache" : "API")")
```

## When NOT to Use DataFetcher

DataFetcher is **not** appropriate for:

1. **Write operations** (POST, PUT, DELETE) - use `APIService` directly
2. **One-time fetches** without caching - use `APIService` directly
3. **Real-time data** that shouldn't be cached - use `APIService` directly
4. **Custom fetch logic** that doesn't fit the cache-first pattern

Examples:
- Fetching individual activity details that change frequently
- Chat messages that need real-time updates
- Auth operations (login, signup)
- One-off data transformations

## Testing

### Mocking DataFetcher

For testing, you can mock the DataFetcher:

```swift
class MockDataFetcher: IDataFetcher {
    var mockResult: FetchResult<Any>?
    
    func fetch<T: Decodable>(
        cacheKey: String,
        cachePolicy: CachePolicy,
        cacheProvider: @escaping () -> T?,
        apiProvider: @escaping () async throws -> T,
        cacheUpdater: @escaping (T) -> Void
    ) async -> FetchResult<T> {
        if let result = mockResult as? FetchResult<T> {
            return result
        }
        return .failure(DataFetcherError.noCachedData)
    }
    
    // Implement other protocol methods...
}
```

## Performance Considerations

### 1. Background Refresh

When using `.cacheFirst(backgroundRefresh: true)`:
- UI updates immediately with cached data
- Background refresh doesn't block the main thread
- Cache is updated silently without re-triggering UI updates

### 2. Parallel Fetching

DataFetcher methods can be called in parallel:
```swift
async let activities = dataFetcher.fetchActivities(userId: userId)
async let friends = dataFetcher.fetchFriends(userId: userId)
async let stats = dataFetcher.fetchProfileStats(userId: userId)

let (activitiesResult, friendsResult, statsResult) = await (activities, friends, stats)
```

### 3. Cache Efficiency

- DataFetcher reuses the existing AppCache infrastructure
- No duplicate caching - data is stored once and shared
- Cache subscriptions still work for reactive updates

## Future Enhancements

Potential improvements to consider:

1. **Request deduplication**: Prevent multiple simultaneous requests for the same data
2. **Cache expiration**: Automatic invalidation based on time
3. **Retry logic**: Automatic retries with exponential backoff
4. **Network status awareness**: Automatically switch to `.cacheOnly` when offline
5. **Prefetching**: Load related data proactively
6. **Analytics**: Track cache hit rates and fetch performance

## Summary

The DataFetcher service provides:
- ✅ Consistent data fetching patterns
- ✅ Reduced code duplication
- ✅ Simplified ViewModel dependencies
- ✅ Flexible caching strategies
- ✅ Easy to test and maintain

By centralizing data fetching logic, the codebase becomes more maintainable and easier to reason about.

