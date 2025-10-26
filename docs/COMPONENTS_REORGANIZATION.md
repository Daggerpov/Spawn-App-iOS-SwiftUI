# Views Folder Reorganization - Page-Centric Structure

## Overview
The Views folder has been reorganized from a master `Components/` folder approach to a **page-centric structure** where components live close to the pages that use them, with truly shared utilities in a dedicated `Views/Shared/` folder.

## New Structure

```
Views/
├── Pages/
│   ├── Activities/
│   │   ├── components/                    # Activity-specific components
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
│   │   │   ├── components/                # Chat-specific components
│   │   │   │   ├── ChatMessageMenuView.swift
│   │   │   │   └── ReportChatMessageDrawer.swift
│   │   │   ├── ChatMessageView.swift
│   │   │   └── ChatroomView.swift
│   │   ├── ActivityCreation/
│   │   │   ├── Components/
│   │   │   └── SubComponents/
│   │   └── [other activity files and folders]
│   ├── Friends/
│   │   ├── components/                    # Friend-specific components
│   │   │   ├── FriendRequestSuccessDrawer.swift
│   │   │   ├── FriendsTabMenuView.swift
│   │   │   └── ReportUserDrawer.swift
│   │   └── [other friend pages]
│   ├── Profile/
│   │   ├── Components/
│   │   └── [other profile pages]
│   ├── AuthFlow/
│   ├── FeedAndMap/
│   └── Events/
└── Shared/                               # Cross-cutting utilities
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
    ├── UI/
    │   ├── Enhanced3DButton.swift
    │   ├── RiveAnimationView.swift
    │   └── StepIndicatorView.swift
    ├── Styles/
    │   └── InnerShadow.swift
    ├── TabBar/
    │   ├── TabBar.swift
    │   ├── TabBarView.swift
    │   ├── TabButtonLabelsView.swift
    │   ├── TabButtonStyle.swift
    │   ├── TabItemModel.swift
    │   ├── TabScrollContentView.swift
    │   └── Tabs.swift
    └── Tutorial/
        ├── TutorialActivityPreConfirmationView.swift
        └── TutorialOverlayView.swift
```

## Migration Summary

### What Changed

**OLD Structure:**
```
Views/Components/           # Master folder with 40+ components
├── Activities/
├── Chat/
├── Friends/
├── Forms/
├── Images/
├── Map/
├── Notifications/
├── Pickers/
├── Shared/
├── Styles/
├── TabBar/
└── Tutorial/
```

**NEW Structure:**
- Page-specific components moved to `Pages/{PageName}/components/`
- Shared utilities moved to `Views/Shared/{Category}/`
- Components now live near the pages that use them

### Component Relocation Map

#### To `Pages/Activities/components/`:
- ActivityBackButton.swift
- ActivityMenuView.swift
- ActivityNextStepButton.swift
- ActivityShareDrawer.swift
- EnhancedActivityShareDrawer.swift
- ActivityTypeNameEditModal.swift
- ParticipantLimitSelectionView.swift
- ReportActivityDrawer.swift
- UserActivitiesSection.swift

#### To `Pages/Activities/Chatroom/components/`:
- ChatMessageMenuView.swift
- ReportChatMessageDrawer.swift

#### To `Pages/Friends/components/`:
- FriendRequestSuccessDrawer.swift
- FriendsTabMenuView.swift
- ReportUserDrawer.swift

#### To `Views/Shared/Forms/`:
- ErrorInputComponents.swift
- SearchBarButtonView.swift
- SearchBarView.swift

#### To `Views/Shared/Images/`:
- CachedAsyncImage.swift

#### To `Views/Shared/Map/`:
- UnifiedMapView.swift

#### To `Views/Shared/Notifications/`:
- ErrorNotificationView.swift
- InAppNotificationView.swift

#### To `Views/Shared/Pickers/`:
- ElegantEmojiPickerWrapper.swift

#### To `Views/Shared/UI/`:
- Enhanced3DButton.swift
- RiveAnimationView.swift
- StepIndicatorView.swift

#### To `Views/Shared/Styles/`:
- InnerShadow.swift

#### To `Views/Shared/TabBar/`:
- All 7 tab bar files

#### To `Views/Shared/Tutorial/`:
- TutorialActivityPreConfirmationView.swift
- TutorialOverlayView.swift

## Import Path Changes

**No import changes required!** Swift's module system means all files remain in the same target, so no import statements need to be updated. The files are simply reorganized within the project structure.

## Benefits of This Reorganization

1. **Page-Centric Organization**: Components live near the pages that use them, making it easier to understand relationships
2. **Clear Separation**: Truly shared utilities (forms, images, notifications) are clearly distinguished in `Views/Shared/`
3. **Better Scalability**: New pages can easily add their own `components/` subfolder
4. **Reduced Cognitive Load**: Instead of one master folder with 40+ files, components are organized by feature
5. **Intuitive Navigation**: Find components by navigating to the page that uses them
6. **Future-Proof**: Easy to add new pages and components following this pattern

## Naming Conventions

- **Page-specific component folders**: lowercase `components/` (following Swift folder conventions)
- **Shared folders**: Capitalized category names (e.g., `Forms/`, `Images/`, `UI/`)
- **File names**: Follow existing Swift naming conventions (PascalCase for types)

## Guidelines for Future Development

### When to Create a New Component

1. **Page-Specific Component**: Create in `Pages/{PageName}/components/`
   - Used only within one page/section
   - Specific to that page's functionality
   - Example: `ActivityBackButton.swift` → `Pages/Activities/components/`

2. **Sub-Page Component**: Create in `Pages/{PageName}/{SubPage}/components/`
   - Used only within a sub-section of a page
   - Example: Chat components → `Pages/Activities/Chatroom/components/`

3. **Shared Utility**: Create in `Views/Shared/{Category}/`
   - Used across multiple pages/sections
   - General-purpose infrastructure
   - Example: `CachedAsyncImage.swift` → `Views/Shared/Images/`

### Creating New Pages

When creating a new page:
1. Create the page folder under `Views/Pages/{NewPageName}/`
2. Create a `components/` subfolder if needed
3. Place page-specific components in the `components/` folder
4. Only move components to `Shared/` if they're truly reused across pages

## Date
Reorganized: October 26, 2025
