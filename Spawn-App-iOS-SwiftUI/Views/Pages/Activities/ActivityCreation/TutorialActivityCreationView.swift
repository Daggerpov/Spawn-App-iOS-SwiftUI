//
//  TutorialActivityCreationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-28.
//

import SwiftUI

struct TutorialActivityCreationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    @StateObject private var tutorialViewModel = TutorialViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: ActivityCreationStep
    @State private var selectedDuration: ActivityDuration = .indefinite
    @State private var showLocationPicker = false
    @State private var showShareSheet = false
    @State private var showPeopleIntroOverlay = false
    
    // Time selection state - now initialized with calculated default values
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var isAM: Bool
    @State private var activityTitle: String = ""
    
    var creatingUser: BaseUserDTO
    var closeCallback: () -> Void
    @Binding var selectedTab: TabType
    private var startingStep: ActivityCreationStep
    
    init(creatingUser: BaseUserDTO, closeCallback: @escaping () -> Void, selectedTab: Binding<TabType>, startingStep: ActivityCreationStep = .activityType) {
        self.creatingUser = creatingUser
        self.closeCallback = closeCallback
        self._selectedTab = selectedTab
        self.startingStep = startingStep
        self._currentStep = State(initialValue: startingStep)
        
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
            
            self._selectedHour = State(initialValue: hour12)
            self._selectedMinute = State(initialValue: minute)
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
        ZStack {
            VStack(spacing: 0) {
                // Content
                content
                    .animation(.easeInOut, value: currentStep)
            }
            .background(Color.white)
            .onAppear {
                handleViewAppear()
            }
            .onChange(of: selectedTab) { newTab in
                handleTabChange(newTab)
            }
            .onChange(of: tutorialViewModel.currentStep) { newStep in
                handleTutorialStepChange(newStep)
            }
            
            // Tutorial overlays
            tutorialOverlays
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch currentStep {
        case .activityType:
            TutorialActivityTypeView(
                selectedActivityType: $viewModel.selectedActivityType,
                onNext: {
                    handleActivityTypeNext()
                }
            )
        case .dateTime:
            TutorialActivityDateTimeView(
                selectedHour: $selectedHour,
                selectedMinute: $selectedMinute,
                isAM: $isAM,
                activityTitle: $activityTitle,
                selectedDuration: $selectedDuration,
                onNext: {
                    handleDateTimeNext()
                },
                onBack: {
                    handleDateTimeBack()
                }
            )
        case .location:
            TutorialActivityLocationView(
                onNext: {
                    handleLocationNext()
                },
                onBack: {
                    handleLocationBack()
                }
            )
        case .preConfirmation:
            TutorialActivityPreConfirmationView(
                onCreateActivity: {
                    handleCreateActivity()
                },
                onBack: {
                    handlePreConfirmationBack()
                }
            )
        case .confirmation:
            ActivityConfirmationView(
                showShareSheet: $showShareSheet,
                onClose: {
                    handleConfirmationClose()
                },
                onBack: {
                    handleConfirmationBack()
                }
            )
        }
    }
    
    private var tutorialOverlays: some View {
        ZStack {
            // People intro overlay
            if tutorialViewModel.isInTutorial && tutorialViewModel.currentStep == .activityCreationPeopleIntro {
                TutorialPeopleIntroOverlay {
                    tutorialViewModel.nextStep()
                }
            }
            
            // Next step button focus overlay
            if tutorialViewModel.isInTutorial && 
               (tutorialViewModel.currentStep == .activityCreationPeopleManagement ||
                tutorialViewModel.currentStep == .activityCreationDateTime ||
                tutorialViewModel.currentStep == .activityCreationLocation) {
                TutorialNextStepFocusOverlay(
                    isEnabled: true,
                    onNextStep: {
                        handleTutorialNextStep()
                    }
                )
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleViewAppear() {
        // Initialize activityTitle from view model if it exists
        if let title = viewModel.activity.title, !title.isEmpty {
            activityTitle = title
        }
        
        // If we're starting fresh (no pre-selected type), ensure absolutely clean state
        if currentStep == .activityType && viewModel.selectedActivityType == nil {
            ActivityCreationViewModel.forceReset()
            ActivityCreationViewModel.reInitialize()
        }
        
        // Check if we should show the people intro overlay
        if tutorialViewModel.isInTutorial && tutorialViewModel.currentStep == .activityCreationPeopleIntro {
            showPeopleIntroOverlay = true
        }
    }
    
    private func handleTabChange(_ newTab: TabType) {
        // Reset to beginning if activities tab is selected and we're at confirmation
        if newTab == TabType.creation && currentStep == .confirmation {
            currentStep = .activityType
            ActivityCreationViewModel.reInitialize()
            resetActivityCreationState()
        }
        // Also reset when navigating to creation tab from other tabs (not from confirmation)
        else if newTab == TabType.creation && currentStep != .confirmation {
            currentStep = .activityType
            // Only reinitialize if we don't already have a selection (to preserve any pre-selection from feed)
            if viewModel.selectedActivityType == nil {
                ActivityCreationViewModel.reInitialize()
            }
            resetActivityCreationState()
        }
    }
    
    private func handleTutorialStepChange(_ newStep: TutorialStep) {
        switch newStep {
        case .activityCreationPeopleIntro:
            // Show people intro overlay
            showPeopleIntroOverlay = true
        case .activityCreationPeopleManagement:
            // Move to activity type step to show people management
            currentStep = .activityType
        case .activityCreationDateTime:
            // Move to date time step
            currentStep = .dateTime
        case .activityCreationLocation:
            // Move to location step
            currentStep = .location
        case .activityCreationConfirmation:
            // Move to pre-confirmation step
            currentStep = .preConfirmation
        case .completed:
            // Tutorial completed, move to confirmation
            currentStep = .confirmation
        default:
            break
        }
    }
    
    private func handleActivityTypeNext() {
        if tutorialViewModel.isInTutorial {
            tutorialViewModel.nextStep()
        } else {
            currentStep = .dateTime
        }
    }
    
    private func handleDateTimeNext() {
        // Sync the activity title with the view model before proceeding
        let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespaces)
        
        // Validate the title is not empty
        if trimmedTitle.isEmpty {
            return
        }
        
        viewModel.activity.title = trimmedTitle
        
        // Sync selectedDate and selectedDuration with viewModel
        let calendar = Calendar.current
        let hour24 = isAM ? (selectedHour == 12 ? 0 : selectedHour) : (selectedHour == 12 ? 12 : selectedHour + 12)
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour24
        components.minute = selectedMinute
        components.second = 0
        
        if let newDate = calendar.date(from: components) {
            viewModel.selectedDate = newDate
        }
        viewModel.selectedDuration = selectedDuration
        
        if tutorialViewModel.isInTutorial {
            tutorialViewModel.nextStep()
        } else {
            currentStep = .location
        }
    }
    
    private func handleDateTimeBack() {
        if startingStep == .dateTime {
            ActivityCreationViewModel.reInitialize()
            closeCallback()
        } else {
            if tutorialViewModel.isInTutorial {
                // In tutorial, go back to people management
                tutorialViewModel.currentStep = .activityCreationPeopleManagement
            } else {
                currentStep = currentStep.previous()
            }
        }
    }
    
    private func handleLocationNext() {
        // Ensure title is still synced when moving from location to preConfirmation
        if !activityTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            viewModel.activity.title = activityTitle.trimmingCharacters(in: .whitespaces)
        }
        
        if tutorialViewModel.isInTutorial {
            tutorialViewModel.nextStep()
        } else {
            currentStep = .preConfirmation
        }
    }
    
    private func handleLocationBack() {
        if tutorialViewModel.isInTutorial {
            tutorialViewModel.currentStep = .activityCreationDateTime
        } else {
            currentStep = currentStep.previous()
        }
    }
    
    private func handleCreateActivity() {
        // Create the activity and move to confirmation
        if tutorialViewModel.isInTutorial {
            tutorialViewModel.nextStep()
        } else {
            currentStep = .confirmation
        }
    }
    
    private func handlePreConfirmationBack() {
        if tutorialViewModel.isInTutorial {
            tutorialViewModel.currentStep = .activityCreationLocation
        } else {
            currentStep = currentStep.previous()
        }
    }
    
    private func handleConfirmationClose() {
        if tutorialViewModel.isInTutorial {
            tutorialViewModel.completeTutorial()
        }
        ActivityCreationViewModel.reInitialize()
        closeCallback()
    }
    
    private func handleConfirmationBack() {
        if tutorialViewModel.isInTutorial {
            tutorialViewModel.currentStep = .activityCreationConfirmation
        } else {
            currentStep = currentStep.previous()
        }
    }
    
    private func handleTutorialNextStep() {
        tutorialViewModel.nextStep()
    }
    
    private func resetActivityCreationState() {
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
}

// MARK: - Tutorial-Aware Activity Creation Components

// These are wrapper views that add tutorial functionality to the existing components
struct TutorialActivityTypeView: View {
    @Binding var selectedActivityType: ActivityTypeDTO?
    let onNext: () -> Void
    
    var body: some View {
        ActivityTypeView(
            selectedActivityType: $selectedActivityType,
            onNext: onNext
        )
    }
}

struct TutorialActivityDateTimeView: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var isAM: Bool
    @Binding var activityTitle: String
    @Binding var selectedDuration: ActivityDuration
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ActivityDateTimeView(
            selectedHour: $selectedHour,
            selectedMinute: $selectedMinute,
            isAM: $isAM,
            activityTitle: $activityTitle,
            selectedDuration: $selectedDuration,
            onNext: onNext,
            onBack: onBack
        )
    }
}

struct TutorialActivityLocationView: View {
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ActivityCreationLocationView(
            onNext: onNext,
            onBack: onBack
        )
    }
}

struct TutorialActivityPreConfirmationView: View {
    let onCreateActivity: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ActivityPreConfirmationView(
            onCreateActivity: onCreateActivity,
            onBack: onBack
        )
    }
} 