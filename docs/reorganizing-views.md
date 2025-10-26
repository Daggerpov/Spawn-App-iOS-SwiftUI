After planning with Cursor's Plan mode:

These are the requirements/prompts I gave:

Reorganize the folders for views better, by rethinking how they should be organized to begin with, by planning. I want it to be fundamentally broken up by pages, and further into sub-pages, components. Currently, I don't like how we have this master-folder of @Components/ . Rather, I wish the top level was organized by page like in @Pages/ , and the pages such as Pages/Activities/Creation had a sub-folder like "components" 

# Reorganize Views Structure by Page

## Overview

Transform the current structure from a single Components/ master folder into a page-centric organization where:

- Each page/section has its own `components/` subfolder for page-specific components
- Truly shared utilities (forms, images, notifications, etc.) move to `Views/Shared/`
- TabBar and Tutorial remain in `Views/Shared/` as they're cross-cutting concerns

## Current vs Proposed Structure

### Current Structure

```
Views/
├── Components/          # Master folder with 40+ components
│   ├── Activities/
│   ├── Chat/
│   ├── Friends/
│   ├── Forms/
│   ├── Images/
│   ├── Map/
│   ├── Notifications/
│   ├── Pickers/
│   ├── Shared/
│   ├── Styles/
│   ├── TabBar/
│   └── Tutorial/
└── Pages/
    ├── Activities/
    ├── AuthFlow/
    ├── FeedAndMap/
    ├── Friends/
    └── Profile/
```

### Proposed Structure

```
Views/
├── Pages/
│   ├── Activities/
│   │   ├── components/      # Activity-specific components
│   │   │   ├── ActivityBackButton.swift
│   │   │   ├── ActivityMenuView.swift
│   │   │   ├── ActivityNextStepButton.swift
│   │   │   ├── ActivityShareDrawer.swift
│   │   │   ├── EnhancedActivityShareDrawer.swift
│   │   │   ├── ActivityTypeNameEditModal.swift
│   │   │   ├── ParticipantLimitSelectionView.swift
│   │   │   ├── ReportActivityDrawer.swift
│   │   │   └── UserActivitiesSection.swift
│   │   ├── Chatroom/
│   │   │   ├── components/
│   │   │   │   ├── ChatMessageMenuView.swift
│   │   │   │   └── ReportChatMessageDrawer.swift
│   │   │   ├── ChatMessageView.swift
│   │   │   └── ChatroomView.swift
│   │   └── [existing files and folders]
│   ├── Friends/
│   │   ├── components/
│   │   │   ├── FriendRequestSuccessDrawer.swift
│   │   │   ├── FriendsTabMenuView.swift
│   │   │   └── ReportUserDrawer.swift
│   │   └── [existing files]
│   └── [other pages]
└── Shared/             # Cross-cutting utilities and infrastructure
    ├── Forms/
    │   ├── ErrorInputComponents.swift
    │   ├── SearchBarButtonView.swift
    │   └── SearchBarView.swift
    ├── Images/
    │   └── CachedAsyncImage.swift
    ├── Map/
    │   └── UnifiedMapView.swift
    ├── Notifications/
    │   ├── ErrorNotificationView.swift
    │   └── InAppNotificationView.swift
    ├── Pickers/
    │   └── ElegantEmojiPickerWrapper.swift
    ├── UI/              # General UI components
    │   ├── Enhanced3DButton.swift
    │   ├── RiveAnimationView.swift
    │   └── StepIndicatorView.swift
    ├── Styles/
    │   └── InnerShadow.swift
    ├── TabBar/
    │   └── [7 tab bar files]
    └── Tutorial/
        └── [2 tutorial files]
```

## Implementation Steps

### Phase 1: Create New Structure

1. Create `Views/Shared/` directory with subfolders:

   - `Shared/Forms/`
   - `Shared/Images/`
   - `Shared/Map/`
   - `Shared/Notifications/`
   - `Shared/Pickers/`
   - `Shared/UI/`
   - `Shared/Styles/`
   - `Shared/TabBar/`
   - `Shared/Tutorial/`

2. Create page-specific component folders:

   - `Pages/Activities/components/`
   - `Pages/Activities/Chatroom/components/`
   - `Pages/Friends/components/`

### Phase 2: Move Components by Category

**Activity Components** → `Pages/Activities/components/`:

- ActivityBackButton.swift
- ActivityMenuView.swift
- ActivityNextStepButton.swift
- ActivityShareDrawer.swift
- EnhancedActivityShareDrawer.swift
- ActivityTypeNameEditModal.swift
- ParticipantLimitSelectionView.swift
- ReportActivityDrawer.swift
- UserActivitiesSection.swift

**Chat Components** → `Pages/Activities/Chatroom/components/`:

- ChatMessageMenuView.swift
- ReportChatMessageDrawer.swift

**Friend Components** → `Pages/Friends/components/`:

- FriendRequestSuccessDrawer.swift
- FriendsTabMenuView.swift
- ReportUserDrawer.swift

**Shared Forms** → `Views/Shared/Forms/`:

- ErrorInputComponents.swift (used in AuthFlow and Profile)
- SearchBarButtonView.swift (used in Friends)
- SearchBarView.swift (used in Friends)

**Shared Images** → `Views/Shared/Images/`:

- CachedAsyncImage.swift (used in 13+ files across all pages)

**Shared Map** → `Views/Shared/Map/`:

- UnifiedMapView.swift (used in FeedAndMap and ActivityCreation)

**Shared Notifications** → `Views/Shared/Notifications/`:

- ErrorNotificationView.swift
- InAppNotificationView.swift

**Shared Pickers** → `Views/Shared/Pickers/`:

- ElegantEmojiPickerWrapper.swift

**Shared UI** → `Views/Shared/UI/`:

- Enhanced3DButton.swift (from Components/Shared/)
- RiveAnimationView.swift (from Components/Shared/)
- StepIndicatorView.swift (from Components/Shared/)

**Shared Styles** → `Views/Shared/Styles/`:

- InnerShadow.swift

**Shared TabBar** → `Views/Shared/TabBar/`:

- TabBar.swift
- TabBarView.swift
- TabButtonLabelsView.swift
- TabButtonStyle.swift
- TabItemModel.swift
- TabScrollContentView.swift
- Tabs.swift

**Shared Tutorial** → `Views/Shared/Tutorial/`:

- TutorialActivityPreConfirmationView.swift
- TutorialOverlayView.swift

### Phase 3: Update Xcode Project References

The Xcode project file (`Spawn-App-iOS-SwiftUI.xcodeproj/project.pbxproj`) needs to be updated to reflect the new file locations. This is a complex file with file references and group structures.

### Phase 4: Cleanup

1. Remove empty `Views/Components/` directory and all subdirectories
2. Update `docs/COMPONENTS_REORGANIZATION.md` to reflect the new page-centric structure
3. Verify all files are properly moved and no broken references exist

## Key Benefits

1. **Page-centric organization**: Components live near the pages that use them
2. **Clear separation**: Truly shared utilities in `Views/Shared/` vs page-specific components
3. **Better scalability**: New pages can add their own `components/` folder
4. **Reduced cognitive load**: Smaller, focused directories instead of one master Components folder
5. **Intuitive navigation**: Find components by navigating to the page that uses them

## Notes

- Swift's module system means no import changes needed - all files remain in same target
- Xcode project.pbxproj must be carefully updated to maintain file references
- The term "components" is lowercase to match Swift conventions for subfolders