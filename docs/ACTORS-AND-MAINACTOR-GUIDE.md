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

## Class-Level @MainActor Best Practices

### When to Add @MainActor to a Class

Add `@MainActor` to the entire class when:

1. **It's an `ObservableObject` with `@Published` properties** - SwiftUI requires main thread updates
2. **It accesses `@MainActor`-isolated singletons** (like `DataService.shared`) in its initializer
3. **Most of its methods update UI state**

```swift
// ❌ BAD: Accessing @MainActor singleton from nonisolated init default parameter
class FeedbackViewModel: ObservableObject {
    private var dataService: DataService
    
    init(dataService: DataService? = nil) {
        // Error: Main actor-isolated static property 'shared' cannot be 
        // referenced from a nonisolated autoclosure
        self.dataService = dataService ?? DataService.shared
    }
}

// ✅ GOOD: Class-level @MainActor allows access to @MainActor singletons
@MainActor
class FeedbackViewModel: ObservableObject {
    private var dataService: DataService
    
    init(dataService: DataService? = nil) {
        self.dataService = dataService ?? DataService.shared  // ✅ Works
    }
}
```

---

### Removing Redundant @MainActor from Methods

When a class is marked `@MainActor`, **all its methods are automatically main actor-isolated**. Remove redundant method-level `@MainActor` annotations:

```swift
// ❌ BAD: Redundant @MainActor on methods
@MainActor
class ActivityTypeViewModel: ObservableObject {
    @Published var isLoading = false
    
    @MainActor  // ← Redundant!
    func fetchActivityTypes() async {
        isLoading = true
        // ...
    }
    
    @MainActor  // ← Redundant!
    private func setLoadingState(_ loading: Bool) {
        isLoading = loading
    }
}

// ✅ GOOD: Clean - class-level @MainActor covers all methods
@MainActor
class ActivityTypeViewModel: ObservableObject {
    @Published var isLoading = false
    
    func fetchActivityTypes() async {
        isLoading = true
        // ...
    }
    
    private func setLoadingState(_ loading: Bool) {
        isLoading = loading
    }
}
```

---

### Replacing `await MainActor.run` in @MainActor Classes

When the entire class is `@MainActor`, you don't need `await MainActor.run` to update properties - you're already on the main actor:

```swift
// ❌ BAD: Unnecessary MainActor.run in @MainActor class
@MainActor
class FeedbackViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    
    func submitFeedback() async {
        await MainActor.run {  // ← Unnecessary!
            isSubmitting = true
            errorMessage = nil
        }
        
        let result = await api.submit()
        
        await MainActor.run {  // ← Unnecessary!
            isSubmitting = false
        }
    }
}

// ✅ GOOD: Direct property access - already on main actor
@MainActor
class FeedbackViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    
    func submitFeedback() async {
        isSubmitting = true  // ✅ Direct access
        errorMessage = nil
        
        let result = await api.submit()
        
        isSubmitting = false  // ✅ Direct access
    }
}
```

---

### Common Refactoring Checklist

When adding `@MainActor` to a class, follow these steps:

1. **Add `@MainActor` to the class declaration**
2. **Remove `@MainActor` from individual methods** - they inherit from the class
3. **Replace `await MainActor.run { ... }`** with direct property access
4. **Remove `Task { @MainActor in ... }`** wrappers for simple property updates
5. **Keep `await`** for calling other async methods - the actor hop is still needed

```swift
// Before refactoring
class ActivityCardViewModel: ObservableObject {
    @Published var isParticipating = false
    
    @MainActor
    private func updateState(_ participating: Bool) {
        isParticipating = participating
    }
    
    func toggle() async {
        let result = await api.toggle()
        await MainActor.run {
            isParticipating = result
        }
    }
}

// After refactoring
@MainActor
class ActivityCardViewModel: ObservableObject {
    @Published var isParticipating = false
    
    private func updateState(_ participating: Bool) {  // No @MainActor needed
        isParticipating = participating
    }
    
    func toggle() async {
        let result = await api.toggle()
        isParticipating = result  // Direct access, no MainActor.run
    }
}
```

---

### Handling `deinit` in @MainActor Classes

`deinit` is **always nonisolated** and cannot call @MainActor methods directly. Use `nonisolated(unsafe)` for properties that need cleanup in deinit:

```swift
// ❌ BAD: Cannot call @MainActor methods from deinit
@MainActor
class FeedViewModel: ObservableObject {
    private var refreshTimer: Timer?
    
    private func stopTimer() {  // Implicitly @MainActor
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    deinit {
        stopTimer()  // Error: Call to main actor-isolated method in nonisolated context
    }
}

// ✅ GOOD: Use nonisolated(unsafe) for properties accessed in deinit
@MainActor
class FeedViewModel: ObservableObject {
    // nonisolated(unsafe) allows access from deinit
    private nonisolated(unsafe) var refreshTimer: Timer?
    
    private func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    deinit {
        // Direct cleanup - safe because Timer is nonisolated(unsafe)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
```

**When to use `nonisolated(unsafe)`:**
- Properties that need cleanup in `deinit` (timers, observers)
- Properties that don't need actor isolation guarantees
- Use sparingly - only when necessary for deinit access

---

### Timer Callbacks in @MainActor Classes

Timer callbacks run on a different thread. Use `@MainActor` on the Task to safely access properties:

```swift
@MainActor
class FeedViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    private nonisolated(unsafe) var cleanupTimer: Timer?
    
    private func startPeriodicCleanup() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard self != nil else { return }
            
            // ✅ Use @MainActor Task to access @MainActor properties
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let filtered = self.filterExpiredActivities(self.activities)
                self.activities = filtered
            }
        }
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
| `@MainActor` (class) | Main thread guarantee for all methods | ViewModels, ObservableObjects with @Published |
| `@MainActor` (method) | Main thread for specific method | Non-@MainActor class needing UI updates |
| `Task { }` | Inherits actor context | Spawning work from @MainActor |
| `Task.detached { }` | Background work | Heavy computation, disk I/O |
| `withTaskGroup` | Parallel operations | Batch downloads, parallel fetches |
| `async let` | Fixed parallel calls | 2-5 independent operations |

### Quick Reference: @MainActor Class Refactoring

| Before | After | Why |
|--------|-------|-----|
| `class Foo: ObservableObject` | `@MainActor class Foo: ObservableObject` | Enable access to @MainActor singletons |
| `@MainActor func bar()` (on @MainActor class) | `func bar()` | Redundant - class already isolated |
| `await MainActor.run { prop = x }` (on @MainActor class) | `prop = x` | Already on main actor |
| `Task { @MainActor in ... }` (on @MainActor class) | `Task { ... }` | Task inherits @MainActor context |

---

## Handling Sendable Warnings from Combine

When using `@MainActor` classes with Combine, you may see Sendable-related warnings. Use `@preconcurrency import` to suppress these:

```swift
// ❌ Warning: Add '@preconcurrency' to treat 'Sendable'-related errors 
// from module 'Combine' as warnings
import Combine
import Foundation

@MainActor
class FeedViewModel: ObservableObject {
    private let activitiesSubject = PassthroughSubject<[Activity], Never>()
    // ...
}

// ✅ GOOD: @preconcurrency suppresses Combine Sendable warnings
@preconcurrency import Combine
import Foundation

@MainActor
class FeedViewModel: ObservableObject {
    private let activitiesSubject = PassthroughSubject<[Activity], Never>()
    // ...
}
```

**When to use `@preconcurrency`:**
- Importing modules that haven't fully adopted Sendable (like Combine)
- When you get warnings about non-Sendable types crossing actor boundaries
- As a temporary measure while Apple updates their frameworks

---

## Related Documentation

- `THREADING-FIXES-IMPLEMENTATION.md` - How threading was fixed across the app
- `TASK-GROUPS-IMPLEMENTATION.md` - Task group patterns for parallel work
- `PARALLEL-ASYNC-IMPLEMENTATION.md` - async let patterns
- `NAVIGATION-RACE-CONDITION-FIX.md` - Fixing Task.detached issues in views

---

*Last Updated: December 2025*
*Status: Reference Documentation*
*Recent additions: Class-level @MainActor patterns, deinit handling, Timer callbacks, @preconcurrency import*

