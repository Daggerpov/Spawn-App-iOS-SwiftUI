//
//  TutorialViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 1/21/25.
//

import Foundation
import SwiftUI

class TutorialViewModel: ObservableObject {
    static let shared = TutorialViewModel()
    
    @Published var tutorialState: TutorialState = .notStarted
    @Published var shouldShowCallout: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let tutorialStateKey = "TutorialState"
    private let hasCompletedTutorialKey = "HasCompletedFirstActivityTutorial"
    
    private init() {
        loadTutorialState()
    }
    
    /// Load tutorial state from UserDefaults
    private func loadTutorialState() {
        let hasCompleted = userDefaults.bool(forKey: hasCompletedTutorialKey)
        
        if hasCompleted {
            tutorialState = .completed
        } else {
            // Check if user needs tutorial
            if shouldStartTutorial() {
                tutorialState = .activityTypeSelection
                shouldShowCallout = true
            } else {
                tutorialState = .notStarted
            }
        }
    }
    
    /// Save tutorial state to UserDefaults
    private func saveTutorialState() {
        if case .completed = tutorialState {
            userDefaults.set(true, forKey: hasCompletedTutorialKey)
        }
    }
    
    /// Check if the user should start the tutorial
    /// This should be called when user reaches the main feed for the first time
    private func shouldStartTutorial() -> Bool {
        // Check if user has completed onboarding and this is their first time in the main app
        guard let user = UserAuthViewModel.shared.spawnUser else { return false }
        
        // User should start tutorial if:
        // 1. They haven't completed the tutorial before
        // 2. They have completed basic onboarding
        // 3. They are in the main app (feed view)
        return !userDefaults.bool(forKey: hasCompletedTutorialKey) && 
               UserAuthViewModel.shared.hasCompletedOnboarding
    }
    
    /// Start the tutorial from the beginning
    func startTutorial() {
        DispatchQueue.main.async {
            self.tutorialState = .activityTypeSelection
            self.shouldShowCallout = true
        }
    }
    
    /// Progress to activity creation step
    func progressToActivityCreation(activityType: String) {
        DispatchQueue.main.async {
            self.tutorialState = .activityCreation(selectedActivityType: activityType)
            self.shouldShowCallout = false
        }
    }
    
    /// Complete the tutorial
    func completeTutorial() {
        DispatchQueue.main.async {
            self.tutorialState = .completed
            self.shouldShowCallout = false
            self.saveTutorialState()
        }
    }
    
    /// Reset tutorial state (for testing/debugging)
    func resetTutorial() {
        DispatchQueue.main.async {
            self.tutorialState = .notStarted
            self.shouldShowCallout = false
            self.userDefaults.removeObject(forKey: self.hasCompletedTutorialKey)
        }
    }
    
    /// Check if navigation to a tab should be allowed
    func canNavigateToTab(_ tab: TabType) -> Bool {
        switch tutorialState {
        case .activityTypeSelection:
            // During activity type selection, only allow home tab
            return tab == .home
        case .activityCreation:
            // During activity creation, allow home and creation tabs
            return tab == .home || tab == .creation
        case .notStarted, .completed:
            // No restrictions
            return true
        }
    }
    
    /// Check if user has any friends (to determine if we should skip people management)
    func userHasFriends() -> Bool {
        let cachedFriends = AppCache.shared.getCurrentUserFriends()
        return !cachedFriends.isEmpty
    }
    
    /// Handle activity type selection during tutorial
    func handleActivityTypeSelection(_ activityType: ActivityTypeDTO) {
        guard case .activityTypeSelection = tutorialState else { return }
        
        // Progress to activity creation
        progressToActivityCreation(activityType: activityType.title)
    }
    
    /// Handle activity creation completion during tutorial
    func handleActivityCreationComplete() {
        guard case .activityCreation = tutorialState else { return }
        
        // Complete the tutorial
        completeTutorial()
    }
} 