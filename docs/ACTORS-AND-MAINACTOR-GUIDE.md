# Actors & MainActor Guide

## Overview

This document explains Swift's actor model and how it's used in the Spawn App for thread-safe concurrency.

## What is an Actor?

An **actor** is a reference type that **protects its mutable state** from data races by ensuring only one task can access its properties at a time.

```swift
actor ProfilePictureCache {
    private var memoryCache: [UUID: UIImage] = [:]  // Protected - only one task at a time
    
    func getImage(for userId: UUID) -> UIImage? {
        return memoryCache[userId]  // Safe access
    }
}
```

**Key behavior**: When you call a method on an actor from outside, you must `await` because Swift may need to wait for exclusive access:

```swift
// From outside the actor:
let image = await ProfilePictureCache.shared.getImage(for: userId)
//          ^^^^^ Required - waits for exclusive access
```

---

## How Actor Isolation Works

```
┌─────────────────────────────────────────────┐
│           actor ProfilePictureCache         │
│  ┌───────────────────────────────────────┐  │
│  │  private var memoryCache: [...]       │  │  ← Protected state
│  │  private var inFlightTasks: [...]     │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  Only ONE task can be inside at a time:     │
│                                             │
│  Task A ──►  │ accessing state │            │
│  Task B ──►  │    waiting...   │  ← Suspended until A finishes
│  Task C ──►  │    waiting...   │
└─────────────────────────────────────────────┘
```

### Example: ProfilePictureCache Deduplication

```swift
actor ProfilePictureCache {
    private var inFlightTasks: [UUID: Task<UIImage?, Error>] = [:]
    
    func downloadAndCacheImage(from urlString: String, for userId: UUID) async -> UIImage? {
        // Only one caller can be here at a time
        if let task = inFlightTasks[userId] {
            return try? await task.value  // Wait for existing download
        }
        
        // Create new task - safe because we have exclusive access
        let task = Task { ... }
        inFlightTasks[userId] = task
        // ...
    }
}
```

---

## What is @MainActor?

`@MainActor` is a **special global actor** that ensures code runs on the **main thread**. Essential for UI updates in SwiftUI.

```swift
@MainActor
class FeedViewModel: ObservableObject {
    @Published var activities: [Activity] = []  // UI property - must be on main thread
    
    func updateActivities(_ new: [Activity]) {
        self.activities = new  // Safe - guaranteed main thread
    }
}
```

### Why MainActor Matters

SwiftUI requires all UI updates to happen on the main thread. `@MainActor` guarantees this at compile time:

```swift
// Without @MainActor - potential runtime crash
class BadViewModel {
    @Published var data: [String] = []
    
    func loadData() async {
        let result = await api.fetch()
        self.data = result  // ⚠️ Might be on background thread!
    }
}

// With @MainActor - compile-time safety
@MainActor
class GoodViewModel {
    @Published var data: [String] = []
    
    func loadData() async {
        let result = await api.fetch()
        self.data = result  // ✅ Guaranteed main thread
    }
}
```

---

## Actor vs @MainActor Comparison

| Feature | `actor` | `@MainActor` |
|---------|---------|--------------|
| Thread | Any background thread | Main thread only |
| Use case | Protecting shared state | UI updates |
| Access | Exclusive (one at a time) | Serial on main thread |
| Example in app | `ProfilePictureCache` | `FeedViewModel`, cache services |

---

## How They Work Together in Spawn App

```
┌─────────────────────────────────────────────────────────────────┐
│                         Main Thread                              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  @MainActor FeedViewModel                                │    │
│  │  @MainActor ActivityCacheService                         │    │
│  │  @MainActor FriendshipCacheService                       │    │
│  │  @MainActor ProfileCacheService                          │    │
│  │                                                          │    │
│  │  All UI updates happen here - SwiftUI requires this      │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ await
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Background Threads                          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  actor ProfilePictureCache                               │    │
│  │                                                          │    │
│  │  Downloads images, manages disk cache                    │    │
│  │  Thread-safe without blocking main thread                │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Practical Examples from Spawn App

### 1. Actor Protecting Shared State (ProfilePictureCache)

**Location**: `Services/Cache/ProfilePictureCache.swift`

```swift
actor ProfilePictureCache {
    private var memoryCache: [UUID: UIImage] = [:]
    private var inFlightTasks: [UUID: Task<UIImage?, Error>] = [:]
    
    // Called from @MainActor views - requires await
    func getCachedImageWithRefresh(for userId: UUID, from urlString: String?) async -> UIImage? {
        // Check memory cache (thread-safe)
        if let cached = memoryCache[userId] {
            return cached
        }
        
        // Deduplication: if already downloading, wait for that task
        if let task = inFlightTasks[userId] {
            return try? await task.value
        }
        
        // Download and cache...
    }
}
```

### 2. @MainActor for UI State (ViewModels)

**Location**: `ViewModels/FeedAndMap/FeedViewModel.swift`

```swift
@MainActor
class FeedViewModel: ObservableObject {
    @Published var activities: [FullFeedActivityDTO] = []
    @Published var isLoading = false
    
    func fetchAllData() async {
        isLoading = true  // Safe - on main thread
        
        async let activities: () = fetchActivitiesForUser()
        async let activityTypes: () = activityTypeViewModel.fetchActivityTypes()
        
        await activities
        await activityTypes
        
        isLoading = false  // Safe - on main thread
    }
}
```

### 3. @MainActor Cache Services

**Location**: `Services/Cache/FriendshipCacheService.swift`

```swift
@MainActor
class FriendshipCacheService: BaseCacheService {
    @Published var friends: [UUID: [FullFriendUserDTO]] = [:]
    
    func updateFriendsForUser(_ friends: [FullFriendUserDTO], userId: UUID) {
        self.friends[userId] = friends  // Main thread - safe for SwiftUI
        
        // Cross into actor for background image work
        Task {
            await preloadProfilePictures(for: [userId: friends])
        }
    }
    
    private func preloadProfilePictures<T: Nameable>(for users: [UUID: [T]]) async {
        await withTaskGroup(of: Void.self) { group in
            for (_, userList) in users {
                for user in userList {
                    guard let url = user.profilePicture else { continue }
                    group.addTask {
                        // Crosses from @MainActor → actor
                        _ = await ProfilePictureCache.shared.getCachedImageWithRefresh(
                            for: user.id, from: url
                        )
                    }
                }
            }
        }
    }
}
```

---

## Key Rules

### 1. Actor methods require `await` from outside

```swift
// Correct
let image = await profilePictureCache.getImage(for: userId)

// Compile error
let image = profilePictureCache.getImage(for: userId)  // ❌ Missing await
```

### 2. @MainActor methods require `await` from non-main contexts

```swift
Task.detached {
    await MainActor.run {
        viewModel.updateUI()  // Jump to main thread
    }
}
```

### 3. Inside an actor, no `await` needed for own properties

```swift
actor MyActor {
    var data: [String] = []
    
    func addItem(_ item: String) {
        data.append(item)  // No await - already inside actor
    }
}
```

### 4. `nonisolated` escapes actor isolation

```swift
actor ProfilePictureCache {
    private let metadataKey = "ProfilePictureCacheMetadata"
    
    nonisolated private func loadMetadata() {
        // Can run on any thread
        // But CANNOT access actor's mutable state
        UserDefaults.standard.data(forKey: metadataKey)
    }
}
```

---

## Common Patterns in Spawn App

### Pattern 1: Stale-While-Revalidate

Return cached data immediately, refresh in background:

```swift
actor ProfilePictureCache {
    func getCachedImageWithRefresh(for userId: UUID, from urlString: String?) async -> UIImage? {
        if let cached = memoryCache[userId] {
            if !isStale(for: userId) {
                return cached  // Fresh - return immediately
            }
            
            // Stale - return immediately, refresh in background
            Task.detached(priority: .background) {
                _ = await self.downloadAndCacheImage(from: urlString!, for: userId, forceRefresh: true)
            }
            return cached
        }
        
        // No cache - must download
        return await downloadAndCacheImage(from: urlString!, for: userId)
    }
}
```

### Pattern 2: Background Disk I/O

Load from disk without blocking main thread:

```swift
@MainActor
class FriendshipCacheService {
    private override init() {
        super.init()
        
        // Load from disk in background, update on main actor
        Task.detached { [weak self] in
            await self?.loadFromDiskAsync()
        }
    }
    
    private func loadFromDiskAsync() async {
        let friends = await Task.detached { [weak self] in
            self?.loadFromDefaults(key: "friends")
        }.value
        
        // Update on MainActor (already isolated)
        if let friends { self.friends = friends }
    }
}
```

### Pattern 3: Parallel Downloads with Task Groups

```swift
actor ProfilePictureCache {
    func refreshStaleProfilePictures(for users: [(userId: UUID, profilePictureUrl: String?)]) async {
        await withTaskGroup(of: Void.self) { group in
            for user in users {
                guard let url = user.profilePictureUrl else { continue }
                
                if isProfilePictureStale(for: user.userId) {
                    group.addTask {
                        _ = await self.downloadAndCacheImage(from: url, for: user.userId, forceRefresh: true)
                    }
                }
            }
        }
    }
}
```

---

## Task Types and Actor Isolation

### Task { } - Inherits Current Actor

```swift
@MainActor
class ViewModel {
    func doWork() {
        Task {
            // Still on @MainActor
            self.updateUI()  // ✅ Safe
        }
    }
}
```

### Task { @MainActor in } - Explicit MainActor

```swift
func backgroundWork() {
    Task { @MainActor in
        // Guaranteed main thread
        viewModel.updateUI()
    }
}
```

### Task.detached { } - No Actor Inheritance

```swift
@MainActor
class ViewModel {
    func doWork() {
        Task.detached {
            // NOT on @MainActor - runs on background thread
            await self.heavyComputation()  // ✅ Good for CPU work
            
            await MainActor.run {
                self.updateUI()  // Must explicitly hop back
            }
        }
    }
}
```

---

## Why This Matters

### Before Actors (Manual Synchronization)

```swift
class ImageCache {
    private var cache: [UUID: UIImage] = [:]
    private let queue = DispatchQueue(label: "cache", attributes: .concurrent)
    
    func getImage(for id: UUID) -> UIImage? {
        queue.sync { cache[id] }
    }
    
    func setImage(_ image: UIImage, for id: UUID) {
        queue.async(flags: .barrier) { self.cache[id] = image }
    }
}
// Easy to get wrong, race conditions possible
```

### With Actors (Compiler-Enforced Safety)

```swift
actor ImageCache {
    private var cache: [UUID: UIImage] = [:]
    
    func getImage(for id: UUID) -> UIImage? {
        cache[id]  // Automatically thread-safe
    }
    
    func setImage(_ image: UIImage, for id: UUID) {
        cache[id] = image  // Automatically thread-safe
    }
}
// Compiler prevents race conditions
```

**Key benefit**: If you forget `await`, you get a **compile error** - not a runtime crash.

---

## Summary

| Concept | Purpose | When to Use |
|---------|---------|-------------|
| `actor` | Thread-safe mutable state | Shared caches, network deduplication |
| `@MainActor` | Main thread guarantee | ViewModels, UI-publishing services |
| `Task { }` | Inherits actor context | Spawning work from @MainActor |
| `Task.detached { }` | Background work | Heavy computation, disk I/O |
| `withTaskGroup` | Parallel operations | Batch downloads, parallel fetches |
| `async let` | Fixed parallel calls | 2-5 independent operations |

---

## Related Documentation

- `THREADING-FIXES-IMPLEMENTATION.md` - How threading was fixed across the app
- `TASK-GROUPS-IMPLEMENTATION.md` - Task group patterns for parallel work
- `PARALLEL-ASYNC-IMPLEMENTATION.md` - async let patterns
- `NAVIGATION-RACE-CONDITION-FIX.md` - Fixing Task.detached issues in views

---

*Last Updated: December 2025*
*Status: Reference Documentation*

