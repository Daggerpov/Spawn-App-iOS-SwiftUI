# Map Navigation & Concurrency Fix

## Executive Summary

The MapView is not rendering properly (showing as a grid) and navigation to/from the map tab is broken. The root cause is a **critical interaction between recent concurrency optimizations and SwiftUI's view recreation behavior**, specifically with how `UIViewRepresentable` instances are managed during tab switches.

## Problem Analysis

### Issue 1: View Recreation & MKMapView Lifecycle ⚠️ CRITICAL

**Root Cause:**
The `WithTabBarBinding` component uses a simple `switch` statement with an enum binding. This causes SwiftUI to **completely tear down and recreate views every time you switch tabs**. For `MKMapView` (a `UIViewRepresentable`), this means:

1. Tab away from MapView → `dismantleUIView()` is called → `MKMapView` is destroyed
2. Tab back to MapView → `makeUIView()` is called → New `MKMapView` instance created
3. Map tiles must reload from scratch every time

**Why This Breaks:**
- In `UnifiedMapView.makeUIView()` (line 82-88), there's a `DispatchQueue.main.async` that forces initial render
- However, this async operation can complete **AFTER** the view has already been dismantled if the user tabs away quickly
- This creates a race condition where map initialization is interrupted mid-process
- Recent concurrency changes with `Task.detached` in ContentView (line 126) exacerbate this by adding more async operations competing for main thread time

**Evidence from Code:**
```swift
// UnifiedMapView.swift - Line 82-88
DispatchQueue.main.async {
    mapView.layoutIfNeeded()
    // Force a small region change to trigger tile loading
    let currentRegion = mapView.region
    mapView.setRegion(currentRegion, animated: false)
    print("🗺️ Map view initial render forced")
}
```

This async operation is **not tracked or cancelled** when the view disappears, leading to orphaned operations.

### Issue 2: Task.detached Priority Inversion

**Root Cause:**
The recent concurrency optimization in `ContentView.swift` (line 126) uses `Task.detached(priority: .userInitiated)`:

```swift
backgroundRefreshTask = Task.detached(priority: .userInitiated) {
    let refreshStart = Date()
    await feedViewModel.fetchAllData()
    let refreshDuration = Date().timeIntervalSince(refreshStart)
    print("⏱️ [NAV] ContentView: Background refresh took \(String(format: "%.2f", refreshDuration))s")
    print("✅ [NAV] ContentView: Background refresh completed")
}
```

**Why This Breaks MapView:**
- `Task.detached` runs on a **separate actor context** (not MainActor)
- When `feedViewModel.fetchAllData()` completes, it updates `@Published var activities` 
- This triggers a SwiftUI update that affects the MapView
- However, MapKit operations (like tile loading) **MUST happen on the main thread**
- The detached task can interrupt MapView's main thread work during tab switches

**The Deadly Sequence:**
1. User switches to Map tab
2. MapView's `onAppear` is called
3. MapView begins initializing `MKMapView` 
4. ContentView's `Task.detached` completes and updates `feedViewModel.activities`
5. SwiftUI schedules a re-render of MapView with new activities
6. User switches away before MapView finishes initial render
7. MapView is dismantled mid-initialization
8. Next time user switches to Map, the grid appears because MKMapView's internal state is corrupted

### Issue 3: Missing .id() Modifier for View Identity

**Root Cause:**
SwiftUI cannot properly track view identity across tab switches because there's no stable identifier on the MapView.

**Current Code:**
```swift
case .map:
    MapView(user: user, viewModel: feedViewModel)
        .disabled(tutorialViewModel.tutorialState.shouldRestrictNavigation)
```

**Problem:**
Without an `.id()` modifier, SwiftUI may try to **reuse** the MapView instance when parameters change (like when activities are updated), leading to `updateUIView()` being called on a stale MKMapView reference.

### Issue 4: Coordinator's Parent Reference Race Condition

**Root Cause:**
In `UnifiedMapView.updateUIView()` (line 95):

```swift
func updateUIView(_ mapView: MKMapView, context: Context) {
    // Keep coordinator updated with latest parent state
    context.coordinator.parent = self  // ⚠️ RACE CONDITION
    
    // ... rest of update logic
}
```

**Why This Breaks:**
The coordinator holds a reference to the parent `UnifiedMapView`, but:
1. `updateUIView()` can be called from background threads due to `Task.detached` updates
2. The coordinator's delegate methods (like `mapViewDidFinishLoadingMap`) run on main thread
3. These two threads can access `parent` simultaneously
4. The `parent.onMapLoaded?()` callback (line 341) may execute on a deallocated parent

### Issue 5: Map Loading Callbacks Not Thread-Safe

**Root Cause:**
The map loading delegates in `UnifiedMapView.Coordinator` use `DispatchQueue.main.async` but don't account for view lifecycle:

```swift
// Line 340-342
DispatchQueue.main.async { [weak self] in
    self?.parent.onMapLoaded?()
}
```

**Problem:**
- If the view is dismantled before this async block executes, `parent` points to deallocated memory
- The `weak self` doesn't help because `parent` is not weak
- This can cause the "grid" rendering issue when map tiles fail to load due to callback failure

## Proposed Fixes

### Fix 1: Add View Identity & Caching ✅ HIGHEST PRIORITY

**Location:** `ContentView.swift` - Line 72-74

**Current:**
```swift
case .map:
    MapView(user: user, viewModel: feedViewModel)
        .disabled(tutorialViewModel.tutorialState.shouldRestrictNavigation)
```

**Fixed:**
```swift
case .map:
    MapView(user: user, viewModel: feedViewModel)
        .id("MapView-\(user.id)")  // Stable identity prevents recreation
        .disabled(tutorialViewModel.tutorialState.shouldRestrictNavigation)
```

**Why This Fixes It:**
- Gives SwiftUI a stable identity for the MapView
- Prevents unnecessary recreation when other ContentView state changes
- Ensures `MKMapView` instance survives across minor state updates

### Fix 2: Cancel Async Operations on View Disappear

**Location:** `MapView.swift` - Add state tracking

**Add to MapView:**
```swift
@State private var mapInitializationTask: Task<Void, Never>?
```

**Update `handleViewDisappeared()`:**
```swift
private func handleViewDisappeared() {
    print("🗺️ MapView disappeared")
    locationManager.stopLocationUpdates()
    loadingTimeoutTask?.cancel()
    loadingTimeoutTask = nil
    
    // NEW: Cancel any pending map initialization
    mapInitializationTask?.cancel()
    mapInitializationTask = nil
}
```

**Location:** `UnifiedMapView.swift` - Line 82-88

**Current:**
```swift
// Force initial render and tile loading
DispatchQueue.main.async {
    mapView.layoutIfNeeded()
    // Force a small region change to trigger tile loading
    let currentRegion = mapView.region
    mapView.setRegion(currentRegion, animated: false)
    print("🗺️ Map view initial render forced")
}
```

**Fixed:**
```swift
// Force initial render and tile loading - but track the task
DispatchQueue.main.async { [weak mapView] in
    guard let mapView = mapView else { return }
    mapView.layoutIfNeeded()
    // Force a small region change to trigger tile loading
    let currentRegion = mapView.region
    mapView.setRegion(currentRegion, animated: false)
    print("🗺️ Map view initial render forced")
}
```

**Why This Fixes It:**
- Weak capture prevents accessing deallocated mapView
- Task cancellation stops orphaned async operations
- Prevents race conditions during rapid tab switching

### Fix 3: Use MainActor-Isolated Task Instead of Task.detached

**Location:** `ContentView.swift` - Line 126

**Current:**
```swift
backgroundRefreshTask = Task.detached(priority: .userInitiated) {
    let refreshStart = Date()
    await feedViewModel.fetchAllData()
    let refreshDuration = Date().timeIntervalSince(refreshStart)
    print("⏱️ [NAV] ContentView: Background refresh took \(String(format: "%.2f", refreshDuration))s")
    print("✅ [NAV] ContentView: Background refresh completed")
}
```

**Fixed:**
```swift
backgroundRefreshTask = Task { @MainActor in
    let refreshStart = Date()
    
    guard !Task.isCancelled else {
        print("⚠️ [NAV] ContentView: Background refresh cancelled before starting")
        return
    }
    
    await feedViewModel.fetchAllData()
    let refreshDuration = Date().timeIntervalSince(refreshStart)
    print("⏱️ [NAV] ContentView: Background refresh took \(String(format: "%.2f", refreshDuration))s")
    print("✅ [NAV] ContentView: Background refresh completed")
}
```

**Why This Fixes It:**
- `@MainActor` ensures all updates happen on the main thread
- Proper cancellation check prevents unnecessary work
- No artificial delays - relies on proper sequencing through MainActor isolation
- No more priority inversion between map rendering and data fetching

### Fix 4: Make Coordinator's Parent Reference Thread-Safe

**Location:** `UnifiedMapView.swift` - Add actor isolation

**Current Coordinator:**
```swift
class Coordinator: NSObject, MKMapViewDelegate {
    var parent: UnifiedMapView  // ⚠️ Not thread-safe
    // ...
}
```

**Fixed Coordinator:**
```swift
class Coordinator: NSObject, MKMapViewDelegate {
    var parent: UnifiedMapView
    private var isValid: Bool = true  // Track if coordinator is still valid
    
    // ... existing code ...
    
    func invalidate() {
        isValid = false
    }
}
```

**Update `updateUIView`:**
```swift
func updateUIView(_ mapView: MKMapView, context: Context) {
    // Update parent on main thread only
    DispatchQueue.main.async {
        context.coordinator.parent = self
    }
    
    // Rest of update logic...
}
```

**Update `dismantleUIView`:**
```swift
static func dismantleUIView(_ mapView: MKMapView, coordinator: Coordinator) {
    coordinator.invalidate()  // Mark as invalid
    mapView.delegate = nil
    mapView.removeAnnotations(mapView.annotations)
}
```

**Update all coordinator delegate methods to check validity:**
```swift
func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
    print("🗺️ mapViewDidFinishLoadingMap called")
    guard isValid, !hasReportedLoad else { return }
    hasReportedLoad = true

    DispatchQueue.main.async { [weak self] in
        guard let self = self, self.isValid else { return }
        self.parent.onMapLoaded?()
    }
}
```

**Why This Fixes It:**
- Validity flag prevents callbacks on deallocated views
- Main thread dispatch for parent updates eliminates race conditions
- Weak self captures prevent memory leaks

### Fix 5: Add Proper Lifecycle Hooks to MapView

**Location:** `MapView.swift` - Add proper state management

**Add new state variable:**
```swift
@State private var viewLifecycleState: ViewLifecycleState = .notAppeared

enum ViewLifecycleState {
    case notAppeared
    case appearing
    case appeared
    case disappearing
}
```

**Update `handleViewAppeared()`:**
```swift
private func handleViewAppeared() {
    guard viewLifecycleState != .appeared else {
        print("🗺️ MapView: Ignoring duplicate onAppear")
        return
    }
    
    viewLifecycleState = .appearing
    print("🗺️ MapView appeared")

    // Initialize filtered activities
    updateFilteredActivities()

    // Set initial region (only once)
    if !hasInitialized {
        setInitialRegion()
        hasInitialized = true
    }

    // Start location updates
    if locationManager.authorizationStatus == .authorizedWhenInUse
        || locationManager.authorizationStatus == .authorizedAlways
    {
        locationManager.startLocationUpdates()
    }
    
    viewLifecycleState = .appeared
}
```

**Update `handleViewDisappeared()`:**
```swift
private func handleViewDisappeared() {
    guard viewLifecycleState == .appeared else {
        print("🗺️ MapView: Ignoring disappear when not appeared")
        return
    }
    
    viewLifecycleState = .disappearing
    print("🗺️ MapView disappeared")
    
    locationManager.stopLocationUpdates()
    
    // Cancel any pending map initialization
    mapInitializationTask?.cancel()
    mapInitializationTask = nil
}
```

**Why This Fixes It:**
- Prevents duplicate initialization from rapid tab switches
- State machine ensures proper lifecycle transitions
- Prevents operations from running during teardown
- Map loading relies on delegate callbacks rather than artificial timeouts

### Fix 6: Optimize FeedViewModel Publishing for MapView

**Location:** `FeedViewModel.swift` - Add throttling

**Add to FeedViewModel:**
```swift
import Combine

private var activitiesUpdateThrottle: AnyCancellable?
private let activitiesSubject = PassthroughSubject<[FullFeedActivityDTO], Never>()

init(apiService: IAPIService, userId: UUID) {
    // ... existing init code ...
    
    // Throttle activities updates to prevent overwhelming MapView
    activitiesUpdateThrottle = activitiesSubject
        .throttle(for: .milliseconds(500), scheduler: DispatchQueue.main, latest: true)
        .sink { [weak self] newActivities in
            self?.activities = newActivities
        }
}
```

**Update all places that set activities:**
```swift
// Instead of:
self.activities = fetchedActivities

// Use:
activitiesSubject.send(fetchedActivities)
```

**Why This Fixes It:**
- Prevents rapid-fire updates from overwhelming MapView
- Gives MapView time to properly render between updates
- Reduces the chance of race conditions during tab switches

## Implementation Order

1. **Fix 1** (View Identity) - 5 minutes - CRITICAL
2. **Fix 3** (MainActor isolation) - 10 minutes - CRITICAL
3. **Fix 2** (Cancel operations) - 15 minutes - HIGH
4. **Fix 4** (Thread-safe coordinator) - 20 minutes - HIGH
5. **Fix 5** (Lifecycle state machine) - 20 minutes - MEDIUM
6. **Fix 6** (Throttle updates) - 15 minutes - MEDIUM

**Total estimated time:** 1.5 hours

## Testing Checklist

After implementing fixes:

- [ ] Map renders correctly on first navigation
- [ ] Map persists correctly when switching tabs rapidly (5+ times quickly)
- [ ] Map tiles load properly after switching away and back
- [ ] No memory leaks when switching tabs 50+ times
- [ ] Activities appear correctly on map after background refresh
- [ ] Map location initializes to user location properly
- [ ] No crashes when switching tabs during map initialization
- [ ] Console shows no warnings about main thread violations
- [ ] Profile it with Instruments to verify no priority inversions

## Why the Map Used to Work

The map worked before because:
1. There was no `Task.detached` in ContentView causing priority inversion
2. Activity updates were synchronous on the main thread
3. Less aggressive caching meant fewer rapid state updates

The recent concurrency optimizations improved performance elsewhere but introduced timing issues that exposed pre-existing bugs in MapView lifecycle management.

## Additional Notes

### Why Tabs Other Than Map Work Fine

Other tabs (Home, Friends, Profile, Activities) work fine because:
1. They use native SwiftUI views that handle recreation gracefully
2. They don't use `UIViewRepresentable` which requires manual lifecycle management
3. They don't have the same main thread requirements as MapKit

### Simulator vs Device

The comment in `UnifiedMapView.swift` (line 33-35) notes that the grid issue is more common on Simulator:
```swift
#if targetEnvironment(simulator)
print("⚠️ Running on Simulator - Map tiles may not load properly")
print("⚠️ If you see a grid, try running on a physical device")
#endif
```

However, this is a red herring. The real issue is the race conditions, which:
- Happen on both Simulator and Device
- Are more visible on Simulator due to slower tile loading
- Get masked on Device by faster network/CPU, but still exist

### Performance Impact

These fixes will:
- **Reduce**: Memory usage (fewer leaked tasks)
- **Reduce**: CPU usage (proper task cancellation)
- **Improve**: MapView initialization time (no race conditions)
- **Improve**: User experience (smooth tab switching)
- **No negative impact**: Data fetching still happens in background

## Related Documentation

- `docs/MAIN-THREAD-BLOCKING-FIX.md` - Context on recent threading changes
- `docs/cache-ui-blocking-fix.md` - Related cache optimization work
- `docs/PARALLEL-ASYNC-IMPLEMENTATION.md` - Parallel async patterns used
- `docs/location-manager-singleton-fix.md` - LocationManager threading fixes

## Conclusion

The "grid" rendering and navigation issues are caused by **race conditions between SwiftUI view recreation, MapKit initialization, and recent Task.detached optimizations**. The fixes are straightforward and focus on:

1. Preventing view recreation (view identity)
2. Ensuring proper actor isolation (MainActor)
3. Managing lifecycle properly (cancellation + state machine)
4. Thread safety in coordinator (validity tracking)

These changes will restore map functionality while preserving the performance improvements from recent concurrency work.

