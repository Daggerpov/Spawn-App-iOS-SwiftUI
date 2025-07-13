//
//  TutorialViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-28.
//

import Foundation
import SwiftUI
import Combine

// Tutorial steps that guide the user through their first activity creation
enum TutorialStep: String, CaseIterable {
    case feedViewActivityTypes = "feed_activity_types"
    case activityCreationPeopleIntro = "activity_creation_people_intro"
    case activityCreationPeopleManagement = "activity_creation_people_management"
    case activityCreationDateTime = "activity_creation_date_time"
    case activityCreationLocation = "activity_creation_location"
    case activityCreationConfirmation = "activity_creation_confirmation"
    case completed = "completed"
    
    var title: String {
        switch self {
        case .feedViewActivityTypes:
            return "Welcome to Spawn! Tap on an Activity Type to create your first activity."
        case .activityCreationPeopleIntro:
            return "You're about to chill, who do you want to let know?"
        case .activityCreationPeopleManagement:
            return "Manage your activity participants here."
        case .activityCreationDateTime:
            return "Set when your activity will happen."
        case .activityCreationLocation:
            return "Choose where your activity will take place."
        case .activityCreationConfirmation:
            return "Review and confirm your activity details."
        case .completed:
            return "Great job! You've created your first activity."
        }
    }
    
    var actionButtonText: String {
        switch self {
        case .feedViewActivityTypes:
            return "Tap an activity type"
        case .activityCreationPeopleIntro:
            return "Tap anywhere to continue"
        case .activityCreationPeopleManagement:
            return "Continue"
        case .activityCreationDateTime:
            return "Continue"
        case .activityCreationLocation:
            return "Continue"
        case .activityCreationConfirmation:
            return "Create Activity"
        case .completed:
            return "Finish Tutorial"
        }
    }
    
    func next() -> TutorialStep {
        switch self {
        case .feedViewActivityTypes:
            return .activityCreationPeopleIntro
        case .activityCreationPeopleIntro:
            return .activityCreationPeopleManagement
        case .activityCreationPeopleManagement:
            return .activityCreationDateTime
        case .activityCreationDateTime:
            return .activityCreationLocation
        case .activityCreationLocation:
            return .activityCreationConfirmation
        case .activityCreationConfirmation:
            return .completed
        case .completed:
            return .completed
        }
    }
}

class TutorialViewModel: ObservableObject {
    static let shared = TutorialViewModel()
    
    @Published var isInTutorial: Bool = false
    @Published var currentStep: TutorialStep = .feedViewActivityTypes
    @Published var shouldShowTutorial: Bool = false
    @Published var isActivityTypesLoaded: Bool = false
    @Published var canInteractWithUI: Bool = false
    @Published var selectedActivityTypeForTutorial: ActivityTypeDTO?
    
    private let userDefaults = UserDefaults.standard
    private let tutorialCompletedKey = "tutorial_completed"
    private let tutorialCurrentStepKey = "tutorial_current_step"
    
    private init() {
        loadTutorialState()
    }
    
    // MARK: - Tutorial State Management
    
    /// Starts the tutorial for a new user
    func startTutorial() {
        isInTutorial = true
        currentStep = .feedViewActivityTypes
        shouldShowTutorial = true
        canInteractWithUI = false
        saveTutorialState()
    }
    
    /// Advances to the next tutorial step
    func nextStep() {
        let nextStep = currentStep.next()
        currentStep = nextStep
        
        if nextStep == .completed {
            completeTutorial()
        } else {
            saveTutorialState()
        }
    }
    
    /// Completes the tutorial
    func completeTutorial() {
        isInTutorial = false
        shouldShowTutorial = false
        canInteractWithUI = true
        currentStep = .completed
        
        userDefaults.set(true, forKey: tutorialCompletedKey)
        userDefaults.removeObject(forKey: tutorialCurrentStepKey)
        userDefaults.synchronize()
    }
    
    /// Skips the tutorial entirely
    func skipTutorial() {
        completeTutorial()
    }
    
    /// Checks if the user has completed the tutorial
    func hasTutorialBeenCompleted() -> Bool {
        return userDefaults.bool(forKey: tutorialCompletedKey)
    }
    
    /// Checks if the tutorial should be shown for a new user
    func shouldShowTutorialForNewUser() -> Bool {
        return !hasTutorialBeenCompleted()
    }
    
    /// Enables UI interaction (used when activity types are loaded)
    func enableUIInteraction() {
        canInteractWithUI = true
        isActivityTypesLoaded = true
    }
    
    /// Sets the selected activity type for the tutorial
    func setSelectedActivityType(_ activityType: ActivityTypeDTO) {
        selectedActivityTypeForTutorial = activityType
    }
    
    /// Resets tutorial state for testing
    func resetTutorialForTesting() {
        userDefaults.removeObject(forKey: tutorialCompletedKey)
        userDefaults.removeObject(forKey: tutorialCurrentStepKey)
        userDefaults.synchronize()
        
        isInTutorial = false
        shouldShowTutorial = false
        canInteractWithUI = true
        currentStep = .feedViewActivityTypes
        isActivityTypesLoaded = false
        selectedActivityTypeForTutorial = nil
    }
    
    // MARK: - Private Methods
    
    private func loadTutorialState() {
        let isCompleted = userDefaults.bool(forKey: tutorialCompletedKey)
        
        if isCompleted {
            isInTutorial = false
            shouldShowTutorial = false
            canInteractWithUI = true
            currentStep = .completed
        } else {
            // Check if there's a saved step
            if let savedStepRaw = userDefaults.string(forKey: tutorialCurrentStepKey),
               let savedStep = TutorialStep(rawValue: savedStepRaw) {
                currentStep = savedStep
                isInTutorial = true
                shouldShowTutorial = true
                canInteractWithUI = false
            }
        }
    }
    
    private func saveTutorialState() {
        userDefaults.set(currentStep.rawValue, forKey: tutorialCurrentStepKey)
        userDefaults.synchronize()
    }
} 