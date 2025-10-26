//
//  ActivityCreationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct ActivityCreationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    @ObservedObject var tutorialViewModel = TutorialViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: ActivityCreationStep
    @State private var selectedDuration: ActivityDuration = .indefinite
    @State private var showLocationPicker = false
    @State private var showShareSheet = false
    
    // Time selection state - now initialized with calculated default values
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var isAM: Bool
    @State private var activityTitle: String = ""
    
    var creatingUser: BaseUserDTO
    var closeCallback: () -> Void
    @Binding var selectedTab: TabType
    private var startingStep: ActivityCreationStep
    
    // Track navigation context to determine correct back behavior
    @State private var sourceTab: TabType
    
    init(creatingUser: BaseUserDTO, closeCallback: @escaping () -> Void, selectedTab: Binding<TabType>, startingStep: ActivityCreationStep = .activityType) {
        self.creatingUser = creatingUser
        self.closeCallback = closeCallback
        self._selectedTab = selectedTab
        self.startingStep = startingStep
        
        // Track the source tab to determine correct back navigation
        // If we have a pre-selected activity type and current tab is activities, we likely came from feed
        let hasPreselectedType = ActivityCreationViewModel.shared.selectedActivityType != nil
        self._sourceTab = State(initialValue: hasPreselectedType && selectedTab.wrappedValue == .activities ? .home : selectedTab.wrappedValue)
        
        // If an activity type is pre-selected and we're starting at activityType step,
        // skip directly to dateTime step
        let initialStep = (startingStep == .activityType && ActivityCreationViewModel.shared.selectedActivityType != nil) ? .dateTime : startingStep
        self._currentStep = State(initialValue: initialStep)
        
        // Initialize time values - either from existing activity or calculate next interval
        if startingStep == .dateTime && ActivityCreationViewModel.shared.selectedDate != Date() {
            // Use existing activity time
            let activityDate = ActivityCreationViewModel.shared.selectedDate
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: activityDate)
            let hour24 = components.hour ?? 0
            let minute = components.minute ?? 0
            
            // Convert to 12-hour format
            let hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24)
            let isAM = hour24 < 12
            
            // Ensure minute value is valid for the picker (must be 0, 15, 30, or 45)
            let validMinute = Self.validateMinuteForPicker(minute)
            
            self._selectedHour = State(initialValue: hour12)
            self._selectedMinute = State(initialValue: validMinute)
            self._isAM = State(initialValue: isAM)
        } else {
            // Calculate the next 15-minute interval after current time
            let nextInterval = Self.calculateNextFifteenMinuteInterval()
            self._selectedHour = State(initialValue: nextInterval.hour)
            self._selectedMinute = State(initialValue: nextInterval.minute)
            self._isAM = State(initialValue: nextInterval.isAM)
        }
        
        // Initialize activity title from view model if editing
        self._activityTitle = State(initialValue: ActivityCreationViewModel.shared.activity.title ?? "")
        
        // Initialize duration from view model if editing
        self._selectedDuration = State(initialValue: ActivityCreationViewModel.shared.selectedDuration)
    }
    
    // Helper function to validate minute values for picker compatibility
    static func validateMinuteForPicker(_ minute: Int) -> Int {
        let validMinutes = [0, 15, 30, 45]
        return validMinutes.min(by: { abs($0 - minute) < abs($1 - minute) }) ?? 0
    }
    
    // Helper function to calculate the next 15-minute interval
    static func calculateNextFifteenMinuteInterval() -> (hour: Int, minute: Int, isAM: Bool) {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // Calculate next 15-minute interval
        let nextMinute: Int
        var nextHour = currentHour
        
        if currentMinute < 15 {
            nextMinute = 15
        } else if currentMinute < 30 {
            nextMinute = 30
        } else if currentMinute < 45 {
            nextMinute = 45
        } else {
            nextMinute = 0
            nextHour += 1
            if nextHour >= 24 {
                nextHour = 0
            }
        }
        
        // Convert to 12-hour format
        let isAM = nextHour < 12
        let displayHour = nextHour == 0 ? 12 : (nextHour > 12 ? nextHour - 12 : nextHour)
        
        return (hour: displayHour, minute: nextMinute, isAM: isAM)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            content
                .animation(.easeInOut, value: currentStep)
        }
        .background(universalBackgroundColor)
        .onAppear {
            // Initialize activityTitle from view model if it exists
            if let title = viewModel.activity.title, !title.isEmpty {
                activityTitle = title
            }
            
            // Handle tutorial mode - skip to dateTime if user has no friends
            if case .activityCreation = tutorialViewModel.tutorialState {
                if !tutorialViewModel.userHasFriends() {
                    // Skip to dateTime step for tutorial users with no friends
                    currentStep = .dateTime
                }
            }
            
            // If we have a pre-selected activity type and we're at activityType step, skip to dateTime
            if currentStep == .activityType && viewModel.selectedActivityType != nil {
                currentStep = .dateTime
            }
            // If we're starting fresh (no pre-selected type), ensure absolutely clean state
            else if currentStep == .activityType && viewModel.selectedActivityType == nil {
                // First try force reset
                ActivityCreationViewModel.forceReset()
                // Then full reinitialization to be absolutely sure
                ActivityCreationViewModel.reInitialize()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            // Reset to beginning if activities tab is selected and we're at confirmation
            if newTab == TabType.activities && currentStep == .confirmation {
                currentStep = .activityType
                ActivityCreationViewModel.reInitialize()
                // Reset other state variables as well
                activityTitle = ""
                selectedDuration = .indefinite
                showLocationPicker = false
                showShareSheet = false
                
                // Reset time to next interval
                let nextInterval = Self.calculateNextFifteenMinuteInterval()
                selectedHour = nextInterval.hour
                selectedMinute = nextInterval.minute
                isAM = nextInterval.isAM
            }
            // Also reset when navigating to activities tab from other tabs (not from confirmation)
            else if newTab == TabType.activities && currentStep != .confirmation {
                // If we have a pre-selected activity type, start at dateTime step, otherwise start at activityType
                let hasPreselectedType = viewModel.selectedActivityType != nil
                currentStep = hasPreselectedType ? .dateTime : .activityType
                
                // Update source tab based on whether we have preselection
                if hasPreselectedType {
                    sourceTab = .home  // Likely came from feed
                } else {
                    sourceTab = .activities  // Direct navigation to activities tab
                }
                
                // Only reinitialize if we don't already have a selection (to preserve any pre-selection from feed)
                if viewModel.selectedActivityType == nil {
                    ActivityCreationViewModel.reInitialize()
                }
                // Reset other state variables
                if let title = viewModel.activity.title, !title.isEmpty {
                    activityTitle = title
                } else {
                    activityTitle = ""
                }
                selectedDuration = .indefinite
                showLocationPicker = false
                showShareSheet = false
                
                // Reset time to next interval
                let nextInterval = Self.calculateNextFifteenMinuteInterval()
                selectedHour = nextInterval.hour
                selectedMinute = nextInterval.minute
                isAM = nextInterval.isAM
            }
        }
        .onChange(of: viewModel.selectedActivityType) { _, newActivityType in
            // Update activity type immediately when selection changes to ensure icon is set
            if newActivityType != nil {
                viewModel.updateActivityType()
            }
            
            // If we're at activityType step and an activity type gets selected, skip to dateTime
            if currentStep == .activityType && newActivityType != nil {
                currentStep = .dateTime
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch currentStep {
        case .activityType:
            ActivityTypeView(
                selectedActivityType: $viewModel.selectedActivityType,
                onNext: {
                    currentStep = .dateTime
                }
            )
        case .dateTime:
            ActivityDateTimeView(
                selectedHour: $selectedHour,
                selectedMinute: $selectedMinute,
                isAM: $isAM,
                activityTitle: $activityTitle,
                selectedDuration: $selectedDuration,
                onNext: {
                    print("🔍 DEBUG: ActivityCreationView onNext callback started")
                    // Sync the activity title with the view model before proceeding
                    let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespaces)
                    
                    // Validate the title is not empty
                    if trimmedTitle.isEmpty {
                        print("🔍 DEBUG: Title is empty, returning early")
                        // The validation is handled in ActivityDateTimeView
                        return
                    }
                    
                    print("🔍 DEBUG: Setting activity title: '\(trimmedTitle)'")
                    viewModel.activity.title = trimmedTitle
                    
                    // Add safety checks for tutorial mode to prevent crashes during transition
                    if case .activityCreation = tutorialViewModel.tutorialState {
                        print("📍 Tutorial: Transitioning from dateTime to location step")
                    }
                    
                    print("🔍 DEBUG: About to sync date and duration")
                    // Sync selectedDate and selectedDuration with viewModel
                    let calendar = Calendar.current
                    let hour24 = isAM ? (selectedHour == 12 ? 0 : selectedHour) : (selectedHour == 12 ? 12 : selectedHour + 12)
                    print("🔍 DEBUG: Calculated hour24: \(hour24), selectedMinute: \(selectedMinute)")
                    
                    var components = calendar.dateComponents([.year, .month, .day], from: Date())
                    components.hour = hour24
                    components.minute = selectedMinute
                    components.second = 0
                    
                    print("🔍 DEBUG: Created date components: \(components)")
                    if let newDate = calendar.date(from: components) {
                        print("🔍 DEBUG: Setting selectedDate: \(newDate)")
                        viewModel.selectedDate = newDate
                    } else {
                        print("🔍 DEBUG: Failed to create date from components")
                    }
                    viewModel.selectedDuration = selectedDuration
                    
                    print("🔍 DEBUG: About to transition to location step")
                    // Ensure we're in a safe state before transitioning
                    DispatchQueue.main.async {
                        print("🔍 DEBUG: Setting currentStep to .location")
                        currentStep = .location
                        print("🔍 DEBUG: currentStep set to .location")
                    }
                },
                onBack: {
                    // Determine back navigation based on context:
                    // 1. If editing existing activity (startingStep is dateTime) → close edit flow
                    // 2. If came from feed → go back to home/feed
                    // 3. If came from activities tab → go to activity type selection
                    
                    if startingStep == .dateTime {
                        // Editing existing activity - close edit flow
                        ActivityCreationViewModel.reInitialize()
                        closeCallback()
                    } else if sourceTab == .home {
                        // Came from feed - go back to home/feed
                        ActivityCreationViewModel.reInitialize()
                        selectedTab = TabType.home
                    } else {
                        // Normal flow from activities tab - go to activity type selection
                        currentStep = currentStep.previous()
                    }
                }
            )
        case .location:
            ActivityCreationLocationView(
                onNext: {
                    // Update location selection step state
                    viewModel.isOnLocationSelectionStep = false
                    
                    // Add safety checks for tutorial mode
                    if case .activityCreation = tutorialViewModel.tutorialState {
                        print("📍 Tutorial: Transitioning from location to preConfirmation step")
                    }
                    
                    // Ensure title is still synced when moving from location to preConfirmation
                    if !activityTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                        viewModel.activity.title = activityTitle.trimmingCharacters(in: .whitespaces)
                    }
                    
                    // Update activity type to ensure the correct icon is set before showing preview
                    viewModel.updateActivityType()
                    
                    // Ensure we're in a safe state before transitioning
                    DispatchQueue.main.async {
                        currentStep = .preConfirmation
                    }
                },
                onBack: {
                    // Update location selection step state
                    viewModel.isOnLocationSelectionStep = false
                    currentStep = currentStep.previous()
                }
            )
            .onAppear {
                // Set location selection step state when entering this view
                viewModel.isOnLocationSelectionStep = true
            }
        case .preConfirmation:
            ActivityPreConfirmationView(
                onCreateActivity: {
                    // Create the activity and move to confirmation
                    currentStep = .confirmation
                },
                onBack: {
                    currentStep = currentStep.previous()
                }
            )
            .navigationBarBackButtonHidden(
                // Hide three dots menu during tutorial
                tutorialViewModel.tutorialState.isActive
            )
        case .confirmation:
            ActivityConfirmationView(
                showShareSheet: $showShareSheet,
                onClose: {
                    // Handle tutorial completion
                    if case .activityCreation = tutorialViewModel.tutorialState {
                        tutorialViewModel.handleActivityCreationComplete()
                    }
                    
                    ActivityCreationViewModel.reInitialize()
                    closeCallback()
                },
                onBack: {
                    currentStep = currentStep.previous()
                }
            )
        }
    }
}

// MARK: - Supporting Types

enum ActivityCreationStep {
    case activityType
    case dateTime
    case location
    case preConfirmation
    case confirmation
    
    var title: String {
        switch self {
        case .activityType: return "What are you up to?"
        case .dateTime: return "Activity Details"
        case .location: return "Choose Location"
        case .preConfirmation: return "Confirm"
        case .confirmation: return "Success!"
        }
    }
    
    func previous() -> ActivityCreationStep {
        switch self {
        case .activityType: return .activityType
        case .dateTime: return .activityType
        case .location: return .dateTime
        case .preConfirmation: return .location
        case .confirmation: return .preConfirmation
        }
    }
}

enum ActivityType: String, CaseIterable {
    case foodAndDrink = "Food & Drink"
    case active = "Active"
    case grind = "Grind"
    case chill = "Chill"
    case general = "General"
    
    var icon: String {
        switch self {
        case .foodAndDrink: return "🍽️"
        case .active: return "🏃"
        case .grind: return "💼"
        case .chill: return "🛋️"
        case .general: return "⭐️"
        }
    }
    
    var peopleCount: Int {
        switch self {
        case .foodAndDrink: return 19
        case .active: return 12
        case .grind: return 17
        case .chill: return 7
        case .general: return 14
        }
    }
}

enum ActivityDuration: CaseIterable {
    case indefinite
    case twoHours
    case oneHour
    case thirtyMinutes
    
    var title: String {
        switch self {
        case .indefinite: return "Indefinite"
        case .twoHours: return "2 hours"
        case .oneHour: return "1 hour"
        case .thirtyMinutes: return "30 mins"
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    ActivityCreationView(
        creatingUser: .danielAgapov,
        closeCallback: {
        },
        selectedTab: .constant(TabType.activities)
    ).environmentObject(appCache)
}
