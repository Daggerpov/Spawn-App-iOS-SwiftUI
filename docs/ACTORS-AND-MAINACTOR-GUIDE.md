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

Use `nonisolated` for pure functions that don't access MainActor state:
```swift
@MainActor
class ContactsService: ObservableObject {
    // ✅ Pure function - no MainActor dependencies
    private nonisolated static func cleanPhoneNumber(_ phone: String) -> String {
        phone.filter { $0.isNumber }  // Safe to call from any thread
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

### Pattern 3: Capture Data Before Sendable Closures

When passing data to `@Sendable` closures from `@MainActor` context, capture *before* the closure:

```swift
@MainActor
class CacheService {
    @Published var data: [String: Any] = [:]
    
    func saveToDisk() {
        // ✅ Capture on MainActor BEFORE the closure
        let capturedData = self.data
        
        debouncedSave { [weak self] in  // @Sendable closure
            self?.writeToDefaults(capturedData)  // Uses captured data
        }
    }
}
```

### Pattern 4: @Sendable Completion Handlers

When completion handlers can be called from different actor contexts, mark them `@Sendable` and wrap MainActor code in a Task:

```swift
// ✅ Mark completion as @Sendable
func generateShareURL(completion: @Sendable @escaping (URL) -> Void) {
    ServiceConstants.generateActivityShareCodeURL(for: activityId) { url in
        completion(url ?? fallbackURL)
    }
}

// ✅ When calling: capture values before closure, wrap MainActor code
func shareViaSystem() {
    let title = activityTitle  // Capture before closure
    generateShareURL { url in
        Task { @MainActor in  // Hop to main actor for UI work
            let shareText = "Join \(title)! \(url)"
            UIApplication.shared.open(url)
        }
    }
}
```

### Pattern 5: Extracting Values from Non-Sendable Types

When SDK types aren't Sendable (like Google Sign-In's `GIDGoogleUser`), extract values before creating Tasks:

```swift
func handleSignIn(_ user: GIDGoogleUser) {
    // ✅ Extract Sendable values BEFORE the Task
    let email = user.profile?.email
    let name = user.profile?.name
    let idToken = user.idToken?.tokenString
    
    Task { @MainActor in
        self.email = email      // Uses extracted values
        self.name = name
        self.idToken = idToken
    }
}
```

### Pattern 6: Parallel Downloads with Task Groups

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
- Importing modules that haven't fully adopted Sendable (Combine, CoreLocation, UserNotifications)
- When you get warnings about non-Sendable types crossing actor boundaries

**For protocol conformances with non-Sendable parameters:**
```swift
// ✅ Use @preconcurrency on protocol conformance when delegate methods receive non-Sendable types
class AppDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate, @preconcurrency MessagingDelegate {
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Handle notification on main actor
    }
}
```

---

## Making Services Sendable for Cross-Actor Usage

When `@MainActor` classes call async methods on service objects (like `IAPIService`), those services must be `Sendable` to be safely passed across actor boundaries.

### The Problem: Data Race Warnings

```swift
// ❌ WARNING: Sending 'self.apiService' risks causing data races
@MainActor
final class DataReader {
    private let apiService: IAPIService  // Not Sendable!
    
    func fetchData() async {
        let data = try await apiService.fetchData(from: url)  // ⚠️ Data race risk
    }
}
```

### The Solution: Protocol + Implementation Sendable Conformance

**Step 1: Make the protocol extend Sendable**

```swift
// ✅ GOOD: Protocol requires Sendable conformance
protocol IAPIService: Sendable {
    func fetchData<T: Decodable>(from url: URL) async throws -> T
    func sendData<T: Encodable>(_ object: T, to url: URL) async throws
}
```

**Step 2: Mark implementations as `@unchecked Sendable`**

```swift
// ✅ GOOD: Implementation is @unchecked Sendable
// Safe because URLSession is thread-safe
final class APIService: IAPIService, @unchecked Sendable {
    var errorMessage: String?  // Mutable, but reset at start of each call
    
    func fetchData<T: Decodable>(from url: URL) async throws -> T {
        // URLSession.shared is thread-safe
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

### When to Use `@unchecked Sendable`

Use `@unchecked Sendable` when:
- The class uses thread-safe APIs internally (like `URLSession.shared`)
- Mutable state is reset at the start of each operation (not shared across calls)
- You're certain the implementation is functionally thread-safe

```swift
// ✅ Safe to use @unchecked Sendable:
final class APIService: @unchecked Sendable {
    var errorMessage: String?  // Reset at start of each call
    // Uses URLSession.shared which is thread-safe
}

// ❌ NOT safe for @unchecked Sendable:
class SharedCounter: @unchecked Sendable {
    var count = 0  // Shared mutable state - NOT thread-safe!
}
```

### Mock Services Need the Same Treatment

```swift
// ✅ Mock also needs @unchecked Sendable
final class MockAPIService: IAPIService, @unchecked Sendable {
    var userId: UUID?
    
    func fetchData<T: Decodable>(from url: URL) async throws -> T {
        // Return mock data
    }
}
```

### Subclasses Must Restate Inherited Sendable

When a subclass inherits from a class with `@unchecked Sendable`, it must explicitly restate the conformance:

```swift
// Parent class
class FullFeedActivityDTO: @unchecked Sendable { ... }

// ❌ BAD: Compiler error - must restate inherited conformance
class ProfileActivityDTO: FullFeedActivityDTO { ... }

// ✅ GOOD: Explicitly restate the conformance
class ProfileActivityDTO: FullFeedActivityDTO, @unchecked Sendable { ... }
```

---

## Adding Sendable Constraints to Generic Parameters

When generic parameters are passed across actor boundaries (like in async method calls), they must be `Sendable`.

### The Problem: Generic Body Parameters

```swift
// ❌ WARNING: Sending 'body' risks causing data races
@MainActor
final class DataWriter {
    func write<RequestBody: Encodable>(body: RequestBody) async {
        try await apiService.sendData(body, to: url)  // ⚠️ body not Sendable
    }
}
```

### The Solution: Add `& Sendable` Constraint

```swift
// ✅ GOOD: Require Sendable for cross-actor safety
@MainActor
final class DataWriter {
    func write<RequestBody: Encodable & Sendable>(body: RequestBody) async {
        try await apiService.sendData(body, to: url)  // ✅ Safe
    }
}
```

### Update All Related Types

When you add `Sendable` to a method, update related structs and protocols too:

```swift
// ✅ Struct holding the body must also be Sendable
struct WriteOperation<Body: Encodable & Sendable>: Sendable {
    let method: HTTPMethod
    let endpoint: String
    let body: Body?
}

// ✅ Protocol methods need the constraint
protocol IDataWriter {
    func write<RequestBody: Encodable & Sendable>(
        _ operation: WriteOperation<RequestBody>
    ) async -> DataResult<Response>
}

// ✅ Implementation methods need the constraint
@MainActor
final class DataWriter: IDataWriter {
    func write<RequestBody: Encodable & Sendable>(
        _ operation: WriteOperation<RequestBody>
    ) async -> DataResult<Response> {
        // ...
    }
}
```

### DTOs Are Usually Already Sendable

Most DTOs in Swift are automatically `Sendable` because they're structs with only `Sendable` properties:

```swift
// ✅ This struct is implicitly Sendable
struct ActivityCreateDTO: Encodable {
    let title: String        // Sendable
    let startTime: Date      // Sendable
    let location: Location?  // Sendable if Location is Sendable
}
```

If a DTO isn't `Sendable`, Swift will give a compile error at the call site, making it easy to identify and fix.

---

## All ObservableObjects Should Be @MainActor

Every class that conforms to `ObservableObject` should have `@MainActor`:

### Why Every ObservableObject Needs @MainActor

1. **`@Published` properties must be updated on main thread** - SwiftUI requirement
2. **Singleton `.shared` access from @MainActor classes** - avoids init errors
3. **Consistency** - all UI-related state is on the same actor

### Cache Facades and Wrappers

Even "facade" or "wrapper" classes that don't have their own `@Published` properties need `@MainActor` if they're `ObservableObject`:

```swift
// ❌ BAD: Cache facade without @MainActor causes data race warnings
class AppCache: ObservableObject {
    static let shared = AppCache()
    
    private let activityCache = ActivityCacheService.shared  // @MainActor
    
    var activities: [UUID: [Activity]] {
        activityCache.activities  // Accessing @MainActor property
    }
}

// Causes: "Sending 'self.appCache' risks causing data races"
// when used in Task blocks from @MainActor classes

// ✅ GOOD: Facade with @MainActor
@MainActor
class AppCache: ObservableObject {
    static let shared = AppCache()
    
    private let activityCache = ActivityCacheService.shared
    
    var activities: [UUID: [Activity]] {
        activityCache.activities  // Safe - same actor
    }
}
```

### Checklist for ObservableObject Classes

When creating or migrating an `ObservableObject`:

- [ ] Add `@MainActor` to the class declaration
- [ ] Remove redundant `@MainActor` from methods
- [ ] Remove unnecessary `await MainActor.run { }` blocks
- [ ] Ensure stored services/dependencies are also `@MainActor` or `Sendable`
- [ ] Use `nonisolated(unsafe)` for properties accessed in `deinit`

---

## Migration Checklist Summary

When migrating a file to proper actor isolation:

### For ViewModels / ObservableObjects:
1. Add `@MainActor` to the class
2. Remove `@MainActor` from individual methods
3. Remove `await MainActor.run { }` for property updates
4. Keep `await` for async method calls

### For Service Protocols (like IAPIService):
1. Add `: Sendable` to the protocol
2. Add `@unchecked Sendable` to implementations that use thread-safe APIs
3. Mark implementations as `final class`

### For Generic Methods Crossing Actor Boundaries:
1. Add `& Sendable` constraint to generic type parameters
2. Update related structs to also be `: Sendable`
3. Update protocol declarations to match

### For Cache/Facade Classes:
1. Add `@MainActor` even if they're just wrappers
2. Ensure underlying services are also `@MainActor`

---

## Related Documentation

- `THREADING-FIXES-IMPLEMENTATION.md` - How threading was fixed across the app
- `TASK-GROUPS-IMPLEMENTATION.md` - Task group patterns for parallel work
- `PARALLEL-ASYNC-IMPLEMENTATION.md` - async let patterns
- `NAVIGATION-RACE-CONDITION-FIX.md` - Fixing Task.detached issues in views

---

*Last Updated: December 2025*
*Status: Reference Documentation*

