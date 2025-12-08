# Observable Migration Progress

## Overview

This document tracks the progress of migrating from `ObservableObject` + `@Published` to the modern `@Observable` macro as outlined in [OBSERVABLE-MIGRATION-GUIDE.md](./OBSERVABLE-MIGRATION-GUIDE.md).

**Migration Started:** December 8, 2025

---

## Migration Status Summary

| Category | Total | Migrated | Remaining |
|----------|-------|----------|-----------|
| High Priority | 5 | 2 | 3 |
| Medium Priority | 4 | 3 | 1 |
| Lower Priority | 12 | 1 | 11 |
| **Total** | **21** | **6** | **15** |

---

## ViewModels Inventory

### High Priority (Core Features)

| ViewModel | Status | Notes |
|-----------|--------|-------|
| `FeedViewModel` | ⏳ Pending | Uses Combine for throttling and notifications |
| `MapViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ProfileViewModel` | ✅ Completed | Migrated Dec 8, 2025 (largest migration so far) |
| `ActivityCreationViewModel` | ⏳ Pending | Semi-singleton pattern, complex state |
| `UserAuthViewModel` | ⏳ Pending | Singleton, NSObject subclass, complex auth logic |

### Medium Priority (Social Features)

| ViewModel | Status | Notes |
|-----------|--------|-------|
| `FriendRequestViewModel` | ✅ Completed | Migrated Dec 8, 2025 (not used in Views yet) |
| `FriendRequestsViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ChatViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `FriendsTabViewModel` | ⏳ Pending | To be reviewed |

### Lower Priority (Supporting Features)

| ViewModel | Status | Notes |
|-----------|--------|-------|
| `FeedbackViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `BlockedUsersViewModel` | ⏳ Pending | To be reviewed |
| `MyReportsViewModel` | ⏳ Pending | To be reviewed |
| `SearchViewModel` | ⏳ Pending | To be reviewed |
| `ActivityCardViewModel` | ⏳ Pending | To be reviewed |
| `ActivityDescriptionViewModel` | ⏳ Pending | To be reviewed |
| `ActivityInfoViewModel` | ⏳ Pending | To be reviewed |
| `ActivityStatusViewModel` | ⏳ Pending | To be reviewed |
| `ActivityTypeViewModel` | ⏳ Pending | To be reviewed |
| `DayActivitiesViewModel` | ⏳ Pending | To be reviewed |
| `TutorialViewModel` | ⏳ Pending | To be reviewed |
| `VerificationCodeViewModel` | ⏳ Pending | To be reviewed |

---

## Migration Log

### Phase 1: Lower Priority ViewModels (Start Simple)

Starting with simpler ViewModels to establish patterns before tackling complex ones.

#### FeedbackViewModel
- **Status:** ✅ Completed
- **Complexity:** Low
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Simple ViewModel, successfully migrated
- **Files Changed:**
  - `ViewModels/Profile/FeedbackViewModel.swift` - Added `@Observable`, removed `@Published`
  - `Views/Pages/Profile/MyProfile/Settings/Feedback/FeedbackView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Profile/MyProfile/Settings/Feedback/Components/FeedbackStatusView.swift` - Removed `@ObservedObject`
  - `Views/Pages/Profile/MyProfile/Settings/Feedback/Components/SubmitButtonView.swift` - Removed `@ObservedObject`

#### FriendRequestViewModel
- **Status:** ✅ Completed
- **Complexity:** Low
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Simple ViewModel with minimal state, not directly used in Views yet
- **Files Changed:**
  - `ViewModels/Friends/FriendRequestViewModel.swift` - Added `@Observable`, removed `@Published`

#### FriendRequestsViewModel
- **Status:** ✅ Completed
- **Complexity:** Low
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Removed unused Combine cancellables
- **Files Changed:**
  - `ViewModels/Friends/FriendRequestsViewModel.swift` - Added `@Observable`, removed `@Published`, removed `import Combine`
  - `Views/Pages/Friends/FriendRequests/FriendRequestsView.swift` - Changed `@StateObject` to `@State`

#### ChatViewModel
- **Status:** ✅ Completed
- **Complexity:** Medium (has reference to ObservableObject activity)
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Activity reference kept as plain var since FullFeedActivityDTO is still ObservableObject
- **Files Changed:**
  - `ViewModels/Activity/ActivityListing/ChatViewModel.swift` - Added `@Observable`, removed `@Published`, removed `@ObservedObject`
  - `Views/Pages/Activities/Chatroom/ChatroomView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Activities/Chatroom/Components/ChatroomContentView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Activities/ActivityPopup/Components/ChatroomButtonView.swift` - Removed `@ObservedObject`

#### MapViewModel
- **Status:** ✅ Completed
- **Complexity:** Low
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Simple ViewModel with activity reference
- **Files Changed:**
  - `ViewModels/FeedAndMap/MapViewModel.swift` - Added `@Observable`, removed `objectWillChange.send()`
  - `Views/Pages/Activities/ActivityPopup/ActivityCardPopupView.swift` - Changed `@StateObject` to `@State`

#### ProfileViewModel
- **Status:** ✅ Completed
- **Complexity:** High (35+ @Published properties, 14 View files using it)
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Largest ViewModel migration, removed objectWillChange.send() call
- **Files Changed:**
  - `ViewModels/Profile/ProfileViewModel.swift` - Added `@Observable`, removed all `@Published`
  - `Views/Pages/Profile/MyProfile/MyProfileView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Profile/UserProfile/UserProfileView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Profile/MyProfile/EditProfile/EditProfileView.swift` - Removed `@ObservedObject`
  - `Views/Pages/Profile/MyProfile/Components/ProfileActionButtonsView.swift` - Removed `@ObservedObject`
  - `Views/Pages/Profile/Shared/FriendActivitiesShowAllView.swift` - Removed `@ObservedObject`
  - `Views/Pages/Profile/Shared/Components/ProfileInterestsView.swift` - Removed `@ObservedObject`
  - `Views/Pages/Profile/MyProfile/EditProfile/Components/InterestsSection.swift` - Removed `@ObservedObject`
  - `Views/Pages/Activities/Shared/UserActivitiesSection.swift` - Removed `@ObservedObject`
  - `Views/Pages/Profile/MyProfile/Calendar/ProfileCalendarView.swift` - Changed `@StateObject` to plain var
  - `Views/Pages/Profile/Shared/Calendar/ActivityCalendarView.swift` - Changed `@StateObject` to plain var
  - `Views/Pages/Profile/Shared/Components/ProfileStatsView.swift` - Changed `@StateObject` to plain var
  - `Views/Pages/Profile/Shared/Calendar/ActivityCalendarView/MonthCalendarView.swift` - Changed `@StateObject` to plain var
  - `Views/Pages/Profile/MyProfile/DayActivities/DayActivitiesPageView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Profile/MyProfile/Components/ProfileEditButtonsView.swift` - Changed `@StateObject` to plain var

---

## Migration Checklist Template

For each ViewModel migration:

### ViewModel Migration
- [ ] Add `import Observation`
- [ ] Replace `class MyViewModel: ObservableObject` with `@Observable class MyViewModel`
- [ ] Remove all `@Published` property wrappers
- [ ] Keep `@MainActor` annotation
- [ ] Remove unused `private var cancellables = Set<AnyCancellable>()` (if not needed for Combine pipelines)
- [ ] Update computed properties if needed
- [ ] Test ViewModel in isolation

### View Updates
- [ ] Replace `@StateObject private var viewModel = ...` with `@State private var viewModel = ...`
- [ ] Replace `@ObservedObject var viewModel: ...` with `var viewModel: ...` (plain property)
- [ ] Verify all view bindings still work
- [ ] Test view renders correctly
- [ ] Test all interactions work as expected

---

## Special Considerations

### ViewModels Using Combine

The following ViewModels use Combine for purposes other than observation (throttling, debouncing, notifications):

1. **FeedViewModel** - Uses `PassthroughSubject` for throttling activity updates, uses `NotificationCenter.default.publisher` for various notifications
2. **FriendRequestsViewModel** - Uses `Set<AnyCancellable>` (but may not need it)

These will need to retain their Combine imports and `cancellables` even after migration.

### ViewModels with @ObservedObject Properties

The following ViewModels use `@ObservedObject` internally for nested observable objects:

1. **MapViewModel** - Has `@ObservedObject var activity: FullFeedActivityDTO`
2. **ChatViewModel** - Has `@ObservedObject private var activity: FullFeedActivityDTO`
3. **FeedViewModel** - Has `@Published var activityTypeViewModel: ActivityTypeViewModel`

These need special handling - the nested objects should also be migrated to `@Observable`.

### Singleton ViewModels

1. **UserAuthViewModel** - Uses `static let shared` pattern
2. **ActivityCreationViewModel** - Uses semi-singleton with `static var shared`

These need careful migration to ensure singleton behavior is preserved.

### NSObject Subclasses

1. **UserAuthViewModel** - Inherits from `NSObject` for `ASAuthorizationControllerDelegate`

This requires special handling as `@Observable` works with classes, but we need to ensure protocol conformance is maintained.

---

## Testing Strategy

### Unit Testing
- [ ] Verify all @Published properties are properly observed after migration
- [ ] Verify computed properties update correctly
- [ ] Verify async operations still trigger UI updates

### Integration Testing
- [ ] Test navigation flows
- [ ] Test data loading and display
- [ ] Test error handling and display

### UI Testing
- [ ] Verify no excessive re-renders
- [ ] Verify smooth animations and transitions
- [ ] Test on different iOS versions (17+)

---

## Rollback Plan

If issues are discovered after migration:

1. Each migration is done per-ViewModel with associated View changes
2. Git commits are atomic - one ViewModel + Views per commit
3. Revert specific commits if needed
4. Keep this document updated with any issues encountered

---

## References

- [Apple Documentation: Migrating from ObservableObject](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro)
- [Swift Observation Framework](https://developer.apple.com/documentation/observation)
- [WWDC23: Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [OBSERVABLE-MIGRATION-GUIDE.md](./OBSERVABLE-MIGRATION-GUIDE.md)

