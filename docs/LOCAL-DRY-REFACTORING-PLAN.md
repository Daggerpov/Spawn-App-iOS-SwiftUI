# Local DRY Refactoring Plan

## Objective
Identify and refactor local code duplication within individual files, focusing on:
- Repeated code blocks within the same file
- Duplicated logic that could be extracted to helper methods
- Repeated computed properties
- Duplicated formatting/calculation logic
- Repeated view builders
- Magic numbers and strings that could be constants

## Directory-by-Directory Analysis Plan

### Phase 1: ViewModels (Business Logic)
- [ ] `ViewModels/Activity/`
- [ ] `ViewModels/AuthFlow/`
- [ ] `ViewModels/FeedAndMap/`
- [ ] `ViewModels/Friends/`
- [ ] `ViewModels/Profile/`

### Phase 2: Services (Core Utilities)
- [ ] `Services/`
- [ ] `Services/API/`
- [ ] `Services/SMS/`

### Phase 3: Views - Shared Components
- [ ] `Views/Shared/Forms/`
- [ ] `Views/Shared/Images/`
- [ ] `Views/Shared/Notifications/`
- [ ] `Views/Shared/Pickers/`
- [ ] `Views/Shared/Styles/`
- [ ] `Views/Shared/TabBar/`
- [ ] `Views/Shared/Tutorial/`
- [ ] `Views/Shared/UI/`
- [ ] `Views/ViewModifiers/`

### Phase 4: Views - Pages (Activities)
- [ ] `Views/Pages/Activities/ActivityCard/`
- [ ] `Views/Pages/Activities/ActivityCreation/`
- [ ] `Views/Pages/Activities/ActivityDetail/`
- [ ] `Views/Pages/Activities/ActivityPopup/`
- [ ] `Views/Pages/Activities/Chatroom/`
- [ ] `Views/Pages/Activities/Participants/`
- [ ] `Views/Pages/Activities/Shared/`

### Phase 5: Views - Pages (Auth Flow)
- [ ] `Views/Pages/AuthFlow/`
- [ ] `Views/Pages/AuthFlow/Components/`
- [ ] `Views/Pages/AuthFlow/CoreInputView/`
- [ ] `Views/Pages/AuthFlow/Greeting/`
- [ ] `Views/Pages/AuthFlow/Registration/`

### Phase 6: Views - Pages (Friends & Feed)
- [ ] `Views/Pages/Friends/`
- [ ] `Views/Pages/FeedAndMap/`

### Phase 7: Views - Pages (Profile)
- [ ] `Views/Pages/Profile/`
- [ ] `Views/Pages/Profile/Calendar/`
- [ ] `Views/Pages/Profile/DayActivities/`
- [ ] `Views/Pages/Profile/EditProfile/`
- [ ] `Views/Pages/Profile/Feedback/`
- [ ] `Views/Pages/Profile/ProfileView/`
- [ ] `Views/Pages/Profile/Settings/`

### Phase 8: Models & Extensions
- [ ] `Models/DTOs/`
- [ ] `Models/Enums/`
- [ ] `Extensions/`

## Patterns to Look For

### 1. Repeated View Builders
```swift
// BAD - Repeated pattern
private var header1: some View {
    Text("Title 1").font(.headline).foregroundColor(.blue)
}
private var header2: some View {
    Text("Title 2").font(.headline).foregroundColor(.blue)
}

// GOOD - Extract styling
private func headerText(_ title: String) -> some View {
    Text(title).font(.headline).foregroundColor(.blue)
}
```

### 2. Repeated Formatting Logic
```swift
// BAD - Duplicated date formatting
let formatter1 = DateFormatter()
formatter1.dateFormat = "MMM d, yyyy"
let str1 = formatter1.string(from: date1)

let formatter2 = DateFormatter()
formatter2.dateFormat = "MMM d, yyyy"
let str2 = formatter2.string(from: date2)

// GOOD - Extract to method
private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"
    return formatter.string(from: date)
}
```

### 3. Magic Numbers/Strings
```swift
// BAD
.padding(.horizontal, 20)
.padding(.horizontal, 20)
.padding(.horizontal, 20)

// GOOD
private let horizontalPadding: CGFloat = 20
.padding(.horizontal, horizontalPadding)
```

### 4. Repeated Conditions
```swift
// BAD
if user.id == currentUser?.id && user.isActive {
    // ...
}
if user.id == currentUser?.id && user.isActive {
    // ...
}

// GOOD
private var isCurrentActiveUser: Bool {
    user.id == currentUser?.id && user.isActive
}
```

### 5. Repeated API Calls or Data Fetching
```swift
// BAD - Duplicated error handling
do {
    let result = try await apiService.fetch()
    // handle
} catch {
    errorMessage = error.localizedDescription
}

// GOOD - Extract pattern
private func fetchWithErrorHandling<T>(_ fetch: () async throws -> T) async -> T? {
    do {
        return try await fetch()
    } catch {
        errorMessage = error.localizedDescription
        return nil
    }
}
```

## Refactoring Priorities

### High Priority (Do First)
1. Repeated business logic in ViewModels
2. Duplicated formatting/calculation methods
3. Repeated API call patterns
4. Magic numbers used more than twice

### Medium Priority
5. Repeated view builders
6. Duplicated condition checks
7. Repeated styling patterns

### Low Priority
8. Minor string duplications
9. Single-use helper methods that could be inlined

## Success Metrics
- Lines of code reduced per file
- Number of helper methods/computed properties extracted
- Reduction in cyclomatic complexity
- Improved code readability scores

## Notes
- Maintain backwards compatibility
- Ensure no linter errors introduced
- Add comments for extracted methods
- Keep method names descriptive
- Don't over-abstract (balance is key)

