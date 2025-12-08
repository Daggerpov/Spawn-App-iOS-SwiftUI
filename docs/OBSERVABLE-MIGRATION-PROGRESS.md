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
| Lower Priority | 12 | 9 | 3 |
| **Total** | **21** | **14** | **7** |

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
| `FriendsTabViewModel` | ⏳ Pending | Uses Combine for cache subscriptions |

### Lower Priority (Supporting Features)

| ViewModel | Status | Notes |
|-----------|--------|-------|
| `FeedbackViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `BlockedUsersViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `MyReportsViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `SearchViewModel` | ⏳ Pending | Uses Combine for debouncing |
| `ActivityCardViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ActivityDescriptionViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ActivityInfoViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ActivityStatusViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ActivityTypeViewModel` | ⏳ Pending | Uses Combine for cache subscriptions |
| `DayActivitiesViewModel` | ⏳ Pending | Uses Combine (may not need it) |
| `TutorialViewModel` | ✅ Completed | Migrated Dec 8, 2025 (singleton) |
| `VerificationCodeViewModel` | ✅ Completed | Migrated Dec 8, 2025 |

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

### Phase 2: Continue Lower Priority ViewModels

#### BlockedUsersViewModel
- **Status:** ✅ Completed
- **Complexity:** Low
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Simple ViewModel with API calls
- **Files Changed:**
  - `ViewModels/Profile/BlockedUsersViewModel.swift` - Added `@Observable`, removed `@Published`
  - `Views/Pages/Profile/MyProfile/Settings/BlockedUsersView.swift` - Changed `@StateObject` to `@State`

#### MyReportsViewModel
- **Status:** ✅ Completed
- **Complexity:** Low
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Simple ViewModel with API calls
- **Files Changed:**
  - `ViewModels/Profile/MyReportsViewModel.swift` - Added `@Observable`, removed `@Published`
  - `Views/Pages/Profile/MyProfile/Settings/MyReportsView.swift` - Changed `@StateObject` to `@State`

#### ActivityCardViewModel
- **Status:** ✅ Completed
- **Complexity:** Low
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Simple ViewModel for activity card interactions
- **Files Changed:**
  - `ViewModels/Activity/ActivityListing/ActivityCardViewModel.swift` - Added `@Observable`, removed `@Published`
  - `Views/Pages/Activities/ActivityCard/ActivityCardView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Pages/Activities/ActivityPopup/Components/ParticipationButtonView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Pages/Activities/ActivityPopup/ActivityCardPopupView.swift` - Changed `@StateObject` to `@State`

#### ActivityStatusViewModel
- **Status:** ✅ Completed
- **Complexity:** Low
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Simple ViewModel for status display with timer
- **Files Changed:**
  - `ViewModels/Activity/ActivityListing/ActivityStatusViewModel.swift` - Added `@Observable`, removed `@Published`
  - `Views/Pages/Activities/ActivityCard/ActivityStatusView.swift` - Changed `@StateObject` to `@State`

#### ActivityDescriptionViewModel
- **Status:** ✅ Completed
- **Complexity:** Medium
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Removed `objectWillChange.send()` calls
- **Files Changed:**
  - `ViewModels/Activity/ActivityListing/ActivityDescriptionViewModel.swift` - Added `@Observable`, removed `@Published`, removed `objectWillChange.send()`
  - `Views/Pages/Activities/ActivityDetail/ActivityDescriptionView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Pages/Activities/ActivityDetail/ActivityEditView.swift` - Changed `@ObservedObject` to plain var

#### ActivityInfoViewModel
- **Status:** ✅ Completed
- **Complexity:** Low
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Removed `objectWillChange.send()` call, had `@ObservedObject` internal properties
- **Files Changed:**
  - `ViewModels/Activity/ActivityListing/ActivityInfoViewModel.swift` - Added `@Observable`, removed `@ObservedObject`, removed `objectWillChange.send()`
  - `Views/Pages/Activities/ActivityDetail/ActivityInfo/ActivityInfoView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Pages/Activities/ActivityCard/ActivityLocationView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Events/EventInfoViews/EventInfoView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Pages/Activities/ActivityPopup/ActivityCardPopupView.swift` - Changed `@StateObject` to `@State`

#### TutorialViewModel
- **Status:** ✅ Completed
- **Complexity:** Low (singleton)
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Singleton pattern preserved with `static let shared`
- **Files Changed:**
  - `ViewModels/AuthFlow/TutorialViewModel.swift` - Added `@Observable`, removed `@Published`
  - `Views/Shared/Tutorial/TutorialOverlayView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Shared/Tutorial/TutorialActivityPreConfirmationView.swift` - Changed `@ObservedObject` to plain var
  - `ContentView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Pages/Activities/ActivityCreation/ActivityCreationView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Shared/TabBar/TabBar.swift` - Changed `@ObservedObject` to plain var
  - `Views/Pages/FeedAndMap/ActivityFeedView.swift` - Changed `@ObservedObject` to plain var

#### VerificationCodeViewModel
- **Status:** ✅ Completed
- **Complexity:** Low
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Simple ViewModel with timer, removed Combine import
- **Files Changed:**
  - `ViewModels/AuthFlow/VerificationCodeViewModel.swift` - Added `@Observable`, removed `@Published`, removed `import Combine`
  - `Views/Pages/AuthFlow/Registration/VerificationCodeView.swift` - Changed `@StateObject` to `@State`

---

## Additional Fixes During Migration

During the migration, the following additional fixes were required:

1. **InterestsSection.swift** - Removed `objectWillChange.send()` calls that were referencing ProfileViewModel
2. **EditProfileView.swift** - Updated Preview to use `@State` instead of `@StateObject` for ProfileViewModel
3. **TutorialActivityPreConfirmationView.swift** - Removed `private` from tutorialViewModel to fix memberwise initializer issue
4. **TabBar.swift** - Removed `private` from tutorialViewModel to fix memberwise initializer issue

---

## Migration Checklist Template

For each ViewModel migration:

### ViewModel Migration
- [x] Replace `class MyViewModel: ObservableObject` with `@Observable class MyViewModel`
- [x] Add `final` to class declaration for better optimization
- [x] Remove all `@Published` property wrappers
- [x] Keep `@MainActor` annotation
- [x] Remove unused `private var cancellables = Set<AnyCancellable>()` (if not needed for Combine pipelines)
- [x] Remove `objectWillChange.send()` calls (no longer needed)
- [x] Remove `import Combine` if not used for other purposes
- [x] **Note:** No need to add `import Observation` - it's exported by Foundation

### View Updates
- [x] Replace `@StateObject private var viewModel = ...` with `@State private var viewModel = ...`
- [x] Replace `@ObservedObject var viewModel: ...` with `var viewModel: ...` (plain property)
- [x] Update Previews to use `@State` instead of `@StateObject`
- [x] Remove `private` from plain var properties that have default values (for memberwise initializer)
- [x] Verify all view bindings still work
- [x] Test view renders correctly
- [x] Test all interactions work as expected

---

## Special Considerations

### ViewModels Using Combine (Not Migrated Yet)

The following ViewModels use Combine for purposes other than observation (throttling, debouncing, notifications):

1. **FeedViewModel** - Uses `PassthroughSubject` for throttling activity updates, uses `NotificationCenter.default.publisher` for various notifications
2. **FriendsTabViewModel** - Uses Combine for cache subscriptions and search debouncing
3. **SearchViewModel** - Uses Combine for debouncing search queries
4. **ActivityTypeViewModel** - Uses Combine for cache subscriptions
5. **DayActivitiesViewModel** - Uses Combine (may not need it)

These will need to retain their Combine imports and `cancellables` even after migration, or be refactored to use async/await alternatives.

### Singleton ViewModels

1. **UserAuthViewModel** - Uses `static let shared` pattern, also inherits from NSObject
2. **ActivityCreationViewModel** - Uses semi-singleton with `static var shared`
3. **TutorialViewModel** - ✅ Migrated with singleton pattern preserved

### NSObject Subclasses

1. **UserAuthViewModel** - Inherits from `NSObject` for `ASAuthorizationControllerDelegate`

This requires special handling as `@Observable` works with classes, but we need to ensure protocol conformance is maintained.

---

## Testing Strategy

### Unit Testing
- [ ] Verify all properties are properly observed after migration
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

