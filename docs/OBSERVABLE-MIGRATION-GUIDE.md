# Observable Migration Guide

## Overview

This document outlines the planned migration from the legacy `ObservableObject` + `@Published` pattern to the modern `@Observable` macro introduced in Swift 5.9 / iOS 17+.

## Current State (Legacy Pattern)

Our view models currently use the traditional Combine-based observation pattern:

```swift
import Combine

@MainActor
final class ExampleViewModel: ObservableObject {
    @Published var someState: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // ...
}
```

**In Views:**
```swift
struct ExampleView: View {
    @StateObject private var viewModel = ExampleViewModel()
    // or
    @ObservedObject var viewModel: ExampleViewModel
}
```

## Target State (Modern Pattern)

After migration, view models will use the `@Observable` macro:

```swift
import Observation

@Observable
@MainActor
final class ExampleViewModel {
    var someState: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    
    // No @Published needed
    // No ObservableObject conformance needed
    // No cancellables for observation (may still need for Combine pipelines)
}
```

**In Views:**
```swift
struct ExampleView: View {
    @State private var viewModel = ExampleViewModel()
    // or for passed-in view models:
    var viewModel: ExampleViewModel
}
```

---

## Why Migrate to @Observable?

### 1. Property-Level Observation (Performance)

The most significant benefit is **granular, property-level observation** rather than object-level observation.

| Pattern | Observation Behavior |
|---------|---------------------|
| `ObservableObject` + `@Published` | Any `@Published` property change triggers `objectWillChange`, causing **all** observing views to re-evaluate |
| `@Observable` | Only views that **actually read** a specific property re-render when that property changes |

This results in fewer unnecessary view redraws and improved performance.

### 2. Reduced Boilerplate

```swift
// BEFORE: ObservableObject
class MyViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 0
    @Published var isActive: Bool = false
}

// AFTER: @Observable
@Observable
class MyViewModel {
    var name: String = ""
    var age: Int = 0
    var isActive: Bool = false
}
```

- No `ObservableObject` conformance declaration
- No `@Published` property wrappers
- No manual `objectWillChange` management
- Cleaner, more readable code

### 3. Apple's Recommended Future Direction

As of Swift 5.9 / iOS 17+, `@Observable` is the modern, recommended approach for new SwiftUI code. The Observation framework is essentially the future of SwiftUI model-state design.

### 4. No Combine Dependency for Basic Observation

The `@Observable` macro doesn't rely on Combine for its core observation mechanism, reducing framework dependencies for simple use cases.

---

## Migration Caveats & Considerations

### ⚠️ Minimum Deployment Target

`@Observable` requires:
- **iOS 17+**
- **macOS 14+**
- **Swift 5.9+**

If supporting older OS versions, you must either:
1. Drop support for older versions
2. Use conditional compilation
3. Keep `ObservableObject` for backward compatibility

### ⚠️ Combine Pipeline Considerations

If view models use Combine for side-effects (debounce, throttle, merge, etc.), those patterns don't directly translate. You'll need to:
- Keep `AnyCancellable` storage for any remaining Combine subscriptions
- Consider using `AsyncSequence` alternatives where appropriate
- Refactor Combine pipelines to async/await where possible

### ⚠️ Nested Observable Objects

For hierarchical data models (models containing other models), **all relevant reference types** must be marked with `@Observable` for changes to propagate correctly.

```swift
@Observable
class Parent {
    var child: Child  // Child must also be @Observable for its changes to propagate
}

@Observable
class Child {
    var value: String = ""
}
```

### ⚠️ Threading / @MainActor

`@Observable` itself is thread-safe, but SwiftUI still requires state updates on the main thread. **Always keep `@MainActor`** on view models that perform UI-related updates:

```swift
@Observable
@MainActor  // Still required!
final class MyViewModel {
    var uiState: String = ""
}
```

---

## Migration Checklist

### Per-ViewModel Migration Steps

- [ ] Add `import Observation` (if not already available)
- [ ] Replace `class MyViewModel: ObservableObject` with `@Observable class MyViewModel`
- [ ] Remove all `@Published` property wrappers
- [ ] Keep `@MainActor` annotation
- [ ] Remove unused `private var cancellables = Set<AnyCancellable>()` (unless still needed for Combine pipelines)
- [ ] Update views using the view model

### Per-View Migration Steps

- [ ] Replace `@StateObject private var viewModel = ...` with `@State private var viewModel = ...`
- [ ] Replace `@ObservedObject var viewModel: ...` with `var viewModel: ...` (plain property)
- [ ] For environment injection, replace `@EnvironmentObject` with `@Environment`

### View Property Wrapper Changes

| Old (ObservableObject) | New (@Observable) |
|------------------------|-------------------|
| `@StateObject` | `@State` |
| `@ObservedObject` | Plain `var` or `let` |
| `@EnvironmentObject` | `@Environment` |

---

## Example Migration

### Before (Legacy)

```swift
// ViewModel
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadMessages() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            messages = try await messageService.fetchMessages()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// View
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        List(viewModel.messages) { message in
            MessageRow(message: message)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

### After (Modern)

```swift
// ViewModel
import Observation

@Observable
@MainActor
final class ChatViewModel {
    var messages: [Message] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    func loadMessages() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            messages = try await messageService.fetchMessages()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// View
struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    
    var body: some View {
        List(viewModel.messages) { message in
            MessageRow(message: message)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

---

## ViewModels to Migrate

The following view models in our codebase should be migrated:

### High Priority (Core Features)
- [ ] `FeedViewModel`
- [ ] `MapViewModel`
- [ ] `ProfileViewModel`
- [ ] `EventCreationViewModel`
- [ ] `AuthenticationViewModel`

### Medium Priority (Social Features)
- [ ] `FriendRequestViewModel`
- [ ] `FriendRequestsViewModel`
- [ ] `ChatViewModel`
- [ ] `TagsViewModel`

### Lower Priority (Supporting Features)
- [ ] `FeedbackViewModel`
- [ ] `NotificationsViewModel`
- [ ] Other utility view models

---

## Timeline & Approach

### Recommended Migration Strategy

1. **Phase 1**: Migrate new view models using `@Observable` from the start
2. **Phase 2**: Migrate leaf view models (those not depended on by others)
3. **Phase 3**: Migrate core view models with comprehensive testing
4. **Phase 4**: Clean up any remaining `ObservableObject` usage

### Testing Considerations

After each migration:
- Verify all UI updates correctly in response to state changes
- Check that no views are over-rendering (use SwiftUI's view debugging)
- Ensure async operations still trigger proper UI updates
- Test edge cases around rapid state changes

---

## References

- [Apple Documentation: Migrating from ObservableObject](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [Swift Observation Framework](https://developer.apple.com/documentation/observation)
- [WWDC23: Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/)

---

## Decision

**We will migrate to `@Observable`** for the following reasons:

1. ✅ Our app targets iOS 17+ (or we're willing to update minimum deployment target)
2. ✅ Performance improvements from property-level observation
3. ✅ Reduced boilerplate and cleaner code
4. ✅ Future-proof alignment with Apple's recommended patterns
5. ✅ Our view models primarily use async/await rather than heavy Combine pipelines

**Note**: `ObservableObject` isn't "obsolete" — it's still valid for apps supporting older OS versions. However, for maintainability and modern best practices, `@Observable` is the preferred approach for new code in this project.


