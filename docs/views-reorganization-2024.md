# Views Folder Reorganization - October 2024

## Summary
This document describes the comprehensive reorganization of the `Views/Pages` folder structure to improve code organization, maintainability, and developer experience.

## Goals
1. **Eliminate naming inconsistencies**: Standardized all folder names to use PascalCase
2. **Consolidate scattered components**: Merged `Components`, `SubComponents`, and lowercase variants
3. **Create logical groupings**: Organized files by feature/functionality rather than arbitrary separation
4. **Improve discoverability**: Made it easier to find related files
5. **Better hierarchy**: Created clear parent-child relationships for views and their components

## Major Changes

### 1. Activities Folder
**Previous Structure**: Mixed organization with `components`, `Components`, and `SubComponents` folders

**New Structure**:
```
Activities/
├── ActivityCard/                    # Card display components
│   ├── ActivityCardView.swift
│   ├── ActivityCardTopRowView.swift
│   ├── ActivityLocationView.swift
│   └── ActivityStatusView.swift
├── ActivityCreation/
│   ├── ActivityCreationView.swift
│   └── Steps/                       # Creation flow organized by steps
│       ├── ActivityTypeSelection/
│       │   ├── ActivityTypeView.swift
│       │   ├── ActivityTypeCard.swift
│       │   ├── CreateNewActivityTypeCard.swift
│       │   ├── ActivityTypeEditView.swift
│       │   └── ActivityTypeManagement/
│       │       ├── ActivityTypeManagementView.swift
│       │       ├── ActivityTypeFriendSelectionView.swift
│       │       └── [menu components]
│       ├── LocationSelection/
│       │   ├── ActivityCreationLocationView.swift
│       │   └── [location components]
│       ├── DateTimeSelection/
│       │   └── ActivityDateTimeView.swift
│       ├── InvitePeople/
│       │   ├── InviteFriendsView.swift
│       │   └── InviteView.swift
│       └── Confirmation/
│           ├── ActivityPreConfirmationView.swift
│           ├── ActivityConfirmationView.swift
│           └── ActivitySubmitButtonView.swift
├── ActivityDetail/                  # Detail view and related info
│   ├── ActivityDetailModalView.swift
│   ├── ActivityDescriptionView.swift
│   ├── ActivityEditView.swift
│   └── ActivityInfo/
│       ├── ActivityInfoView.swift
│       ├── ActivityParticipateButtonView.swift
│       └── ParticipantsImagesView.swift
├── ActivityPopup/
│   ├── ActivityCardPopupView.swift
│   ├── ActivityPopupDrawer.swift
│   └── Components/
├── Participants/                    # All participant-related views
│   ├── ActivityParticipantsView.swift
│   ├── AttendeeListView.swift
│   ├── ManagePeopleView.swift
│   └── Components/
├── Chatroom/
│   ├── ChatroomView.swift
│   ├── ChatMessageView.swift
│   └── Components/
├── Shared/                          # Shared activity components
│   ├── ActivityBackButton.swift
│   ├── ActivityNextStepButton.swift
│   ├── ActivityMenuView.swift
│   ├── ActivityTypeCardView.swift
│   ├── ProfilePictureView.swift
│   ├── UserActivitiesSection.swift
│   ├── ParticipantLimitSelectionView.swift
│   └── Drawers/
│       ├── ActivityShareDrawer.swift
│       ├── EnhancedActivityShareDrawer.swift
│       ├── ReportActivityDrawer.swift
│       └── ActivityTypeNameEditModal.swift
└── Utilities/
    └── LocationManager.swift
```

**Key Improvements**:
- Activity creation flow now clearly shows the step-by-step progression
- Merged `Components` and `SubComponents` into logical groupings
- Separated concerns: Card, Detail, Participants, Popup, Chatroom
- Created `Shared` folder for reusable components
- Moved utilities to dedicated folder

### 2. AuthFlow Folder
**Changes**:
- Renamed `SubComponents` → `Components`
- Consolidated `Registration/ContactImportView/` components into `Registration/Components/`
- Maintained clear separation between greeting, login, and registration flows

**New Structure**:
```
AuthFlow/
├── Components/                      # Shared auth components (buttons, etc.)
├── CoreInputView/                   # Custom text field styles
├── Greeting/                        # Welcome/intro screens
├── Registration/
│   ├── Components/                  # Registration-specific components
│   └── [registration views]
└── [root auth views]
```

### 3. FeedAndMap Folder
**Changes**:
- Renamed `SubComponents` → `Components`
- Consolidated `MapView/` subfolder into `Map/Components/`

**New Structure**:
```
FeedAndMap/
├── Components/                      # Feed components (buttons, headers)
├── Map/
│   ├── MapView.swift
│   └── Components/
└── [feed views]
```

### 4. Friends Folder
**Changes**:
- Renamed `components` → `Shared` (for consistency with Activities)
- Consolidated view subfolders properly
- Organized by feature: Requests, Tab, Search

**New Structure**:
```
Friends/
├── FriendRequests/
│   ├── FriendRequestsView.swift
│   └── Components/
├── FriendsTab/
│   ├── FriendsTabView.swift
│   └── Components/
├── Shared/                          # Shared friend components (drawers, menus)
└── [root friend views]
```

### 5. Profile Folder
**Changes**:
- Consolidated `Components` folder contents into respective feature folders
- Better organization by feature: Calendar, EditProfile, Settings, Feedback, DayActivities

**New Structure**:
```
Profile/
├── Calendar/                        # All calendar-related views
│   ├── InfiniteCalendarView.swift
│   ├── ActivityCalendarView/
│   ├── ProfileCalendarView/
│   └── Components/
├── DayActivities/
│   ├── DayActivitiesPageView.swift
│   ├── DayActivitiesView.swift
│   └── Components/
├── EditProfile/
│   ├── EditProfileView.swift
│   └── Components/
├── Feedback/
│   ├── FeedbackView.swift
│   └── Components/
├── ProfileView/
│   ├── ProfileView.swift
│   └── Components/
├── Settings/
│   ├── SettingsView.swift
│   └── Components/
└── [root profile views]
```

## Naming Conventions

### Standardized Folder Names
- **Components**: Used for sub-components of a specific feature
- **Shared**: Used for components shared across multiple features within a module
- **Utilities**: Used for utility files (managers, helpers) that don't fit into view categories

### Case Sensitivity
- All folders now use **PascalCase** (e.g., `Components`, `ActivityCard`)
- Eliminated lowercase variants (`components`, `subComponents`)

## Benefits

1. **Improved Navigation**: Related files are now grouped together logically
2. **Clear Hierarchy**: Parent views and their components are clearly organized
3. **Reduced Confusion**: Eliminated duplicate/similar folder names with different casing
4. **Better Scalability**: New features can follow established patterns
5. **Easier Onboarding**: New developers can understand the structure more quickly

## Migration Notes

- **No Import Changes Required**: Swift doesn't require explicit imports for files within the same module, so the reorganization works seamlessly
- **Git History Preserved**: Files were moved (not deleted/recreated), so git history is maintained
- **No Breaking Changes**: All functionality remains intact

## Verification

- ✅ All files successfully moved to new locations
- ✅ No linter errors after reorganization
- ✅ Git properly tracking file moves as renames
- ✅ Consistent naming conventions applied throughout

## Future Recommendations

1. Consider further breaking down large view files if they exceed 500 lines
2. Add README files in major folders to document their purpose
3. Create view composition guidelines to maintain consistency
4. Consider extracting common components to a dedicated `Views/Shared` folder for cross-module reusability

