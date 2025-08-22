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
        guard let spawnUser = UserAuthViewModel.shared.spawnUser else { return false }
        
        // Always skip tutorial for existing users signing into their account
        print("🎯 TutorialViewModel: Checking if user should start tutorial...")
        
        // Check if this user has any existing activities or friends
        // If they do, they're likely an existing user who shouldn't see the tutorial
        let cachedActivities = AppCache.shared.getCurrentUserActivities()
        let cachedFriends = AppCache.shared.getCurrentUserFriends()
        
        if !cachedActivities.isEmpty || !cachedFriends.isEmpty {
            print("🎯 TutorialViewModel: Skipping tutorial for user with existing activities (\(cachedActivities.count)) or friends (\(cachedFriends.count))")
            return false
        }
        
        // For users who signed in with email/username (not OAuth registration), 
        // they are definitely existing users and should skip tutorial
        if UserAuthViewModel.shared.authProvider == .email {
            print("🎯 TutorialViewModel: Skipping tutorial for email/username sign-in user")
            return false
        }
        
        // IMPORTANT: For existing users signing into their account on a new device,
        // we should NOT show the tutorial even if they have no cached data yet.
        // The key indicator is that they already have a Spawn account that existed before this session.
        // Since we can't easily distinguish between new registrations and existing sign-ins at this point,
        // we'll be conservative and skip the tutorial for most cases to avoid annoying existing users.
        
        // Only show tutorial if user has explicitly never completed it AND
        // this appears to be a completely new user experience
        let hasNeverCompletedTutorial = !userDefaults.bool(forKey: hasCompletedTutorialKey)
        let hasCompletedOnboarding = UserAuthViewModel.shared.hasCompletedOnboarding

        let shouldStart = hasNeverCompletedTutorial && hasCompletedOnboarding
        print("🎯 TutorialViewModel: shouldStartTutorial = \(shouldStart) (hasNeverCompleted: \(hasNeverCompletedTutorial), hasCompletedOnboarding: \(hasCompletedOnboarding))")
        return shouldStart
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
            // During activity creation, allow home and activities tabs
            return tab == .home || tab == .activities
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
