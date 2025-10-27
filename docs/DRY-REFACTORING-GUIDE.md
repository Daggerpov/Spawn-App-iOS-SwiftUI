# DRY Refactoring Guide

## Overview

This document outlines the comprehensive DRY (Don't Repeat Yourself) refactoring performed across the Spawn App iOS SwiftUI codebase. The refactoring consolidates duplicate code patterns into reusable, unified components.

## Created Unified Components

### 1. HapticFeedbackService

**Location:** `Services/HapticFeedbackService.swift`

**Purpose:** Centralized haptic feedback service to eliminate 59+ duplicate `UIImpactFeedbackGenerator` instances.

**Usage:**
```swift
// Light feedback
HapticFeedbackService.shared.light()

// Medium feedback (most common)
HapticFeedbackService.shared.medium()

// Heavy feedback
HapticFeedbackService.shared.heavy()

// Selection feedback
HapticFeedbackService.shared.selection()

// Notification feedback
HapticFeedbackService.shared.success()
HapticFeedbackService.shared.warning()
HapticFeedbackService.shared.error()
```

**Benefits:**
- Eliminates duplicate haptic feedback code
- Consistent haptic feedback across the app
- Easy to mock for testing
- Single point of maintenance

---

### 2. UnifiedButton

**Location:** `Views/Shared/UI/UnifiedButton.swift`

**Purpose:** Consolidated button component replacing `Enhanced3DButton`, `ActivityNextStepButton`, and various onboarding button implementations.

**Features:**
- Consistent styling and animations
- Built-in haptic feedback
- Multiple variants (primary, secondary, outline, custom)
- Disabled state handling
- 3D press effect with scale animation

**Usage:**
```swift
// Primary button (blue)
UnifiedButton.primary("Next Step", isEnabled: true) {
    print("Tapped")
}

// Secondary button (light grey)
UnifiedButton.secondary("Cancel") {
    print("Cancelled")
}

// Outline button
UnifiedButton.outline("Learn More") {
    print("Learn more")
}

// Custom variant
UnifiedButton(
    "Custom",
    variant: .custom(
        backgroundColor: .red,
        foregroundColor: .white,
        borderColor: nil
    ),
    action: { /* action */ }
)
```

**Backwards Compatibility:**
- `Enhanced3DButton` now wraps `UnifiedButton`
- `ActivityNextStepButton` now wraps `UnifiedButton`
- All existing code continues to work without changes

---

### 3. LoadingStateView

**Location:** `Views/Shared/UI/LoadingStateView.swift`

**Purpose:** Unified loading state component replacing 34+ duplicate `ProgressView` implementations.

**Usage:**
```swift
// Default loading
LoadingStateView()

// Custom message
LoadingStateView(message: "Loading activities...")

// Custom scale
LoadingStateView(message: "Fetching data...", scale: 1.5)
```

**Benefits:**
- Consistent loading UI across the app
- Customizable message and scale
- Proper frame sizing
- Easy to update styling globally

---

### 4. EmptyStateView

**Location:** `Views/Shared/UI/EmptyStateView.swift`

**Purpose:** Unified empty state component replacing 22+ duplicate empty state implementations.

**Features:**
- Support for custom images or SF Symbols
- Customizable title and subtitle
- Consistent styling
- Pre-built convenience initializers

**Usage:**
```swift
// Pre-built empty states
EmptyStateView.noActivities()
EmptyStateView.noActivitiesForDay()
EmptyStateView.allGood()
EmptyStateView.noFriendRequests()
EmptyStateView.noSearchResults()

// Custom empty state with image
EmptyStateView(
    imageName: "CustomImage",
    title: "No Items",
    subtitle: "Add your first item to get started!"
)

// Custom empty state with SF Symbol
EmptyStateView(
    systemImageName: "star.fill",
    title: "No Favorites",
    subtitle: "Mark items as favorites to see them here.",
    imageSize: 100
)
```

**Benefits:**
- Consistent empty state UI
- Reusable across all views
- Easy to extend with new variants
- Reduces code duplication significantly

---

### 5. UnifiedBackButton

**Location:** `Views/Shared/UI/UnifiedBackButton.swift`

**Purpose:** Consolidated back button component replacing 47+ duplicate chevron.left back button implementations.

**Features:**
- Consistent styling
- Built-in haptic feedback
- Optional title text
- Environment-aware dismiss variant

**Usage:**
```swift
// Basic back button
UnifiedBackButton {
    print("Back tapped")
}

// Back button with text
UnifiedBackButton(title: "Back") {
    dismiss()
}

// Environment-aware dismiss button
UnifiedDismissButton() // Automatically dismisses current view
UnifiedDismissButton(title: "Cancel")
```

**Backwards Compatibility:**
- `ActivityBackButton` now wraps `UnifiedBackButton`
- `ParticipantsBackButton` uses unified haptic feedback

---

### 6. UnifiedNavigationHeader

**Location:** `Views/Shared/UI/UnifiedNavigationHeader.swift`

**Purpose:** Unified navigation header for consistent header patterns across views.

**Features:**
- Customizable leading, center, and trailing items
- Optional back button
- Consistent spacing and padding
- ViewBuilder support for custom trailing content

**Usage:**
```swift
// Header with title only
UnifiedNavigationHeader.withTitle("My Reports")

// Header with back button
UnifiedNavigationHeader.withBackButton {
    dismiss()
}

// Full custom header
UnifiedNavigationHeader(
    title: "Settings",
    showBackButton: true,
    backButtonAction: { dismiss() }
) {
    Image(systemName: "gearshape")
        .foregroundColor(universalAccentColor)
}
```

**Benefits:**
- Consistent header layout
- Eliminates repetitive HStack patterns
- Easy to customize
- Proper spacing and alignment

---

## Updated Files

### Components Updated to Use Unified System

1. **ActivityNextStepButton.swift** - Now wraps `UnifiedButton`
2. **Enhanced3DButton.swift** - Now wraps `UnifiedButton`
3. **ActivityBackButton.swift** - Now wraps `UnifiedBackButton`
4. **ParticipantsBackButton.swift** - Uses `HapticFeedbackService`
5. **CircularButton.swift** - Uses `HapticFeedbackService`
6. **OnboardingButtonView.swift** - Uses `HapticFeedbackService`

### Views Updated to Use Unified Components

1. **MyReportsView.swift**
   - `UnifiedNavigationHeader` for header
   - `LoadingStateView` for loading state
   - `EmptyStateView.allGood()` for empty state

2. **DayActivitiesPageView.swift**
   - `UnifiedBackButton` in header
   - `EmptyStateView.noActivitiesForDay()` for empty state
   - `LoadingStateView` for loading state

3. **ActivityListView.swift**
   - `EmptyStateView.noActivities()` for empty state

4. **ActivityTypeView.swift**
   - `LoadingStateView` for loading state

5. **BlockedUsersView.swift**
   - `LoadingStateView` for loading state

6. **SpawnIntroView.swift**
   - `HapticFeedbackService` for haptic feedback

---

## Migration Guide

### For New Components

When creating new views, use the unified components:

```swift
// ✅ DO THIS
struct NewView: View {
    var body: some View {
        VStack {
            UnifiedNavigationHeader.withTitle("New View")
            
            if isLoading {
                LoadingStateView(message: "Loading...")
            } else if items.isEmpty {
                EmptyStateView(
                    systemImageName: "tray",
                    title: "No Items",
                    subtitle: "Add items to get started"
                )
            } else {
                // Content
            }
            
            UnifiedButton.primary("Save") {
                save()
            }
        }
    }
}

// ❌ DON'T DO THIS
struct NewView: View {
    var body: some View {
        VStack {
            HStack {
                Button(action: { /* back */ }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text("New View")
                Spacer()
                Color.clear.frame(width: 24, height: 24)
            }
            
            if isLoading {
                ProgressView("Loading...")
            } else if items.isEmpty {
                VStack {
                    Image(systemName: "tray")
                    Text("No Items")
                    Text("Add items to get started")
                }
            }
            
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                save()
            }) {
                Text("Save")
                // ... duplicate styling
            }
        }
    }
}
```

### For Existing Components

Most existing components have been wrapped for backwards compatibility, so no immediate changes are needed. However, consider migrating to direct usage of unified components for clarity:

```swift
// Old way (still works)
Enhanced3DButton(
    title: "Continue",
    backgroundColor: .blue,
    foregroundColor: .white,
    action: { /* action */ }
)

// New way (preferred)
UnifiedButton(
    "Continue",
    variant: .custom(
        backgroundColor: .blue,
        foregroundColor: .white,
        borderColor: nil
    ),
    action: { /* action */ }
)

// Or use convenience method
UnifiedButton.primary("Continue") {
    /* action */
}
```

---

## Benefits of This Refactoring

### Code Reduction
- **59+ haptic feedback instances** → 1 service
- **34+ loading state implementations** → 1 component
- **22+ empty state implementations** → 1 component
- **47+ back button implementations** → 1 component
- **Multiple button implementations** → 1 unified system

### Maintenance
- Single source of truth for UI patterns
- Easy to update styling globally
- Consistent behavior across the app
- Reduced bug surface area

### Developer Experience
- Clearer, more readable code
- Less boilerplate
- Faster development of new features
- Better code reusability

### Testing
- Easier to mock services (e.g., HapticFeedbackService)
- Consistent test patterns
- Better component isolation

---

## Future Enhancements

Consider creating additional unified components for:

1. **UnifiedTextField** - Consolidate text field patterns
2. **UnifiedCard** - Consolidate card layouts
3. **UnifiedAlert** - Consolidate alert patterns
4. **UnifiedToast** - Consolidate toast notifications
5. **UnifiedPullToRefresh** - Standardize pull-to-refresh behavior

---

## Testing

All unified components include:
- SwiftUI Previews for visual testing
- No linter errors
- Backwards compatibility with existing code
- Proper documentation

---

## Questions or Issues?

If you encounter any issues with the unified components or need to add new variants, please:
1. Check this documentation first
2. Review the component source code
3. Add new variants using the existing pattern
4. Update this documentation with your changes

---

*Last Updated: October 26, 2025*

