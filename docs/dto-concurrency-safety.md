# DTO Concurrency Safety Fixes

## Problem

Swift's strict concurrency checking flagged multiple DTOs with warnings like:
- "Static property is not concurrency-safe because it is nonisolated global shared mutable state"
- "Static property is not concurrency-safe because non-'Sendable' type may have shared mutable state"

## Root Causes

1. **Classes with mutable state** - DTOs defined as `class` are non-Sendable by default
2. **Static `var` instead of `let`** - Mutable global state is unsafe for concurrent access
3. **Missing `Sendable` conformance** - Even structs should explicitly declare Sendable

## Solution

### 1. Convert Classes to Structs
Simple data containers don't need reference semantics:
- `LocationDTO` → struct
- `ActivityTypeDTO` → struct  
- `FullActivityChatMessageDTO` → struct
- `CreateChatMessageDTO` → struct

### 2. Add Sendable Conformance
All DTOs with value-type properties should be explicitly Sendable:
```swift
struct BaseUserDTO: Identifiable, Codable, Hashable, Sendable { ... }
```

### 3. Use `static let` for Mock Data
Change mutable static properties to immutable:
```swift
// Before
static var mockUser: UserDTO = ...

// After  
static let mockUser: UserDTO = ...
```

### 4. Use `nonisolated(unsafe)` for Non-Sendable Types
For classes that must remain classes (e.g., `FullFeedActivityDTO` with `@Published`):
```swift
nonisolated(unsafe) static let mockActivity: FullFeedActivityDTO = ...
```

## Files Modified

### DTOs (Added Sendable)
- `BaseUserDTO`, `UserDTO`, `FullFriendUserDTO`, `RecommendedFriendUserDTO`
- `LocationDTO`, `ActivityTypeDTO`, `BatchActivityTypeUpdateDTO`
- `FullActivityChatMessageDTO`, `CreateChatMessageDTO`
- `FetchFriendRequestDTO`, `FetchSentFriendRequestDTO`, `CreateFriendRequestDTO`

### Enums (Added Sendable)
- `UserRelationshipType`, `ActivityStatus`, `FeedbackType`
- `NavigationState`, `TutorialState`

### Classes (Used nonisolated(unsafe))
- `FullFeedActivityDTO` - Must stay class due to `@Published` and `ObservableObject`

## Guidelines for New DTOs

1. **Prefer structs** over classes for data transfer objects
2. **Always add `Sendable`** conformance to DTOs
3. **Use `static let`** for mock/sample data
4. **Use fixed UUIDs** in mock data for stable identity
5. If a class is required, use `nonisolated(unsafe)` for static properties

