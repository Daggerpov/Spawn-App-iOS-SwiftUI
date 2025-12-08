# Observable Migration Progress

## Overview

This document tracks the progress of migrating from `ObservableObject` + `@Published` to the modern `@Observable` macro as outlined in [OBSERVABLE-MIGRATION-GUIDE.md](./OBSERVABLE-MIGRATION-GUIDE.md).

**Migration Started:** December 8, 2025

---

## Migration Status Summary

| Category | Total | Migrated | Remaining |
|----------|-------|----------|-----------|
| High Priority | 5 | 4 | 1 |
| Medium Priority | 4 | 4 | 0 |
| Lower Priority | 12 | 12 | 0 |
| **Total** | **21** | **20** | **1** |

---

## ViewModels Inventory

### High Priority (Core Features)

| ViewModel | Status | Notes |
|-----------|--------|-------|
| `FeedViewModel` | ✅ Completed | Migrated Dec 8, 2025 (kept Combine for throttling and notifications) |
| `MapViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ProfileViewModel` | ✅ Completed | Migrated Dec 8, 2025 (largest migration so far) |
| `ActivityCreationViewModel` | ✅ Completed | Migrated Dec 8, 2025 (semi-singleton pattern preserved) |
| `UserAuthViewModel` | ⏳ Pending | Singleton, NSObject subclass, complex auth logic |

### Medium Priority (Social Features)

| ViewModel | Status | Notes |
|-----------|--------|-------|
| `FriendRequestViewModel` | ✅ Completed | Migrated Dec 8, 2025 (not used in Views yet) |
| `FriendRequestsViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ChatViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `FriendsTabViewModel` | ✅ Completed | Migrated Dec 8, 2025 (kept Combine for cache subs) |

### Lower Priority (Supporting Features)

| ViewModel | Status | Notes |
|-----------|--------|-------|
| `FeedbackViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `BlockedUsersViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `MyReportsViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `SearchViewModel` | ✅ Completed | Migrated Dec 8, 2025 (kept Combine for debouncing) |
| `ActivityCardViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ActivityDescriptionViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ActivityInfoViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ActivityStatusViewModel` | ✅ Completed | Migrated Dec 8, 2025 |
| `ActivityTypeViewModel` | ✅ Completed | Migrated Dec 8, 2025 (kept Combine for cache subs) |
| `DayActivitiesViewModel` | ✅ Completed | Migrated Dec 8, 2025 (removed unused Combine) |
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

### Phase 3: ViewModels with Combine Dependencies (Keeping Combine for specific use cases)

#### DayActivitiesViewModel
- **Status:** ✅ Completed
- **Complexity:** Low
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Removed unused Combine import and cancellables (wasn't actually using Combine)
- **Files Changed:**
  - `ViewModels/Activity/DayActivitiesViewModel.swift` - Added `@Observable`, removed `@Published`, removed unused Combine
  - `Views/Pages/Profile/MyProfile/DayActivities/DayActivitiesView.swift` - Changed `@StateObject` to `@State`

#### ActivityTypeViewModel
- **Status:** ✅ Completed
- **Complexity:** Medium
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Kept Combine for AppCache subscriptions (reactive updates pattern)
- **Files Changed:**
  - `ViewModels/Activity/ActivityTypeViewModel.swift` - Added `@Observable`, removed `@Published`, kept Combine for cache
  - `Views/Pages/Activities/Participants/ManagePeopleView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Activities/ActivityCreation/Steps/ActivityTypeSelection/ActivityTypeEditView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Activities/ActivityCreation/Steps/ActivityTypeSelection/ActivityTypeManagement/ActivityTypeFriendMenuView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Activities/ActivityCreation/Steps/ActivityTypeSelection/ActivityTypeView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Activities/ActivityCreation/Steps/ActivityTypeSelection/ActivityTypeManagement/ActivityTypeManagementView.swift` - Changed `@StateObject` to `@State`

#### SearchViewModel
- **Status:** ✅ Completed
- **Complexity:** Medium
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Kept Combine for debouncing search queries, added `debouncedSearchTextPublisher` for external subscription
- **Files Changed:**
  - `ViewModels/Friends/SearchViewModel.swift` - Added `@Observable`, removed `@Published`, kept Combine for debouncing, added publisher
  - `Views/Pages/Friends/SearchView.swift` - Changed `@ObservedObject` to `@Bindable` (for binding support with @Observable)
  - `Views/Pages/Friends/FriendSearchView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Friends/FriendsTab/FriendsTabView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Activities/ActivityCreation/Steps/InvitePeople/InviteView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Activities/ActivityCreation/Steps/InvitePeople/InviteFriendsView.swift` - Changed `@StateObject` to `@State`

#### FriendsTabViewModel
- **Status:** ✅ Completed
- **Complexity:** High
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Kept Combine for AppCache subscriptions and SearchViewModel connection, updated `connectSearchViewModel` to use publisher instead of `$debouncedSearchText`
- **Files Changed:**
  - `ViewModels/Friends/FriendsTabViewModel.swift` - Added `@Observable`, removed `@Published`, kept Combine for cache and search
  - `Views/Pages/Friends/FriendsView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Pages/Friends/FriendsTab/FriendsTabView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Pages/Friends/FriendSearchView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Friends/FriendsTab/Components/RecommendedFriendView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Pages/Friends/FriendsTab/Components/RecentlySpawnedView.swift` - Changed `@ObservedObject` to plain var
  - `Views/Pages/Activities/Participants/ManagePeopleView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Activities/ActivityCreation/Steps/InvitePeople/InviteView.swift` - Changed `@StateObject` to `@State`
  - `Views/Pages/Activities/ActivityCreation/Steps/InvitePeople/InviteFriendsView.swift` - Changed `@StateObject` to `@State`

### Phase 4: High Priority ViewModels (Core Features)

#### FeedViewModel
- **Status:** ✅ Completed
- **Complexity:** High
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Kept Combine for throttling activities and NotificationCenter subscriptions. Fixed initialization order issue with `dataService` by using local variable before assignment to stored property.
- **Files Changed:**
  - `ViewModels/FeedAndMap/FeedViewModel.swift` - Added `@Observable`, kept Combine for throttling and notifications
  - `Views/Pages/FeedAndMap/FeedView.swift` - Already using `@State` for viewModel
  - `Views/Pages/FeedAndMap/ActivityFeedView.swift` - Uses plain var (passed from parent)
  - `Views/Pages/FeedAndMap/ActivityListView.swift` - Uses plain var (passed from parent)
  - `Views/Pages/FeedAndMap/FullscreenActivityListView.swift` - Uses plain var (passed from parent)
  - `Views/Pages/FeedAndMap/Map/MapView.swift` - Uses plain var (passed from parent)

#### ActivityCreationViewModel
- **Status:** ✅ Completed
- **Complexity:** Medium
- **Date Started:** December 8, 2025
- **Date Completed:** December 8, 2025
- **Notes:** Semi-singleton pattern preserved with `static var shared`. Views use the shared instance directly.
- **Files Changed:**
  - `ViewModels/Activity/ActivityCreationViewModel.swift` - Added `@Observable`, singleton pattern preserved
  - `Views/Pages/Activities/ActivityCreation/ActivityCreationView.swift` - Added `@Bindable` for binding support with @Observable viewModel
  - `Views/Pages/Activities/ActivityCreation/Steps/DateTimeSelection/ActivityDateTimeView.swift` - Removed `private` from viewModel for memberwise initializer
  - `Views/Shared/TabBar/WithTabBarBinding.swift` - Removed `private` from activityCreationViewModel for memberwise initializer
  - Other views use `ActivityCreationViewModel.shared` directly as plain var

---

## Additional Fixes During Migration

During the migration, the following additional fixes were required:

1. **InterestsSection.swift** - Removed `objectWillChange.send()` calls that were referencing ProfileViewModel
2. **EditProfileView.swift** - Updated Preview to use `@State` instead of `@StateObject` for ProfileViewModel
3. **TutorialActivityPreConfirmationView.swift** - Removed `private` from tutorialViewModel to fix memberwise initializer issue
4. **TabBar.swift** - Removed `private` from tutorialViewModel to fix memberwise initializer issue
5. **FriendRowView (FriendSearchView.swift)** - Changed `private var userAuth` to computed property to fix memberwise initializer issue
6. **SearchView.swift** - Added `@Bindable` wrapper for `@Observable` viewModel to enable bindings
7. **ActivityCreationView.swift** - Added `@Bindable` to viewModel to support bindings with @Observable
8. **ActivityDateTimeView.swift** - Removed `private` from viewModel to fix memberwise initializer issue
9. **WithTabBarBinding.swift** - Removed `private` from activityCreationViewModel to fix memberwise initializer issue
10. **FeedViewModel.swift** - Fixed initialization order issue by using local variable for dataService before assigning to stored property

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

### ViewModels Using Combine (Migrated - Kept Combine for specific use cases)

The following ViewModels were migrated to `@Observable` but kept Combine for specific purposes:

1. **FeedViewModel** ✅ - Kept Combine for throttling activity updates (`PassthroughSubject`) and NotificationCenter subscriptions
2. **FriendsTabViewModel** ✅ - Kept Combine for cache subscriptions and search debouncing
3. **SearchViewModel** ✅ - Kept Combine for debouncing search queries, added publisher for external subscriptions
4. **ActivityTypeViewModel** ✅ - Kept Combine for cache subscriptions
5. **DayActivitiesViewModel** ✅ - Removed unused Combine (wasn't actually using it)

### ViewModels Not Migrated Yet

1. **UserAuthViewModel** - Singleton, inherits from NSObject for `ASAuthorizationControllerDelegate` conformance. This is the only remaining ViewModel not migrated.

### Singleton ViewModels

1. **UserAuthViewModel** - Uses `static let shared` pattern, also inherits from NSObject (not yet migrated)
2. **ActivityCreationViewModel** - ✅ Migrated with semi-singleton `static var shared` pattern preserved
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

