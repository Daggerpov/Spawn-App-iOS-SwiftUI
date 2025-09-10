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
    private let apiService: IAPIService
    
    private init() {
        self.apiService = MockAPIService.isMocking ? MockAPIService() : APIService()
        loadTutorialState()
    }
    
    /// Load tutorial state from UserDefaults and server
    private func loadTutorialState() {
        let hasCompleted = userDefaults.bool(forKey: hasCompletedTutorialKey)
        
        if hasCompleted {
            tutorialState = .completed
        } else {
            // Check server for tutorial completion status
            Task {
                await fetchTutorialStatusFromServer()
            }
            
            // Meanwhile, check if user needs tutorial based on local data
            if shouldStartTutorial() {
                tutorialState = .activityTypeSelection
                shouldShowCallout = true
            } else {
                tutorialState = .notStarted
            }
        }
    }
    
    /// Save tutorial state to UserDefaults and server
    private func saveTutorialState() {
        if case .completed = tutorialState {
            userDefaults.set(true, forKey: hasCompletedTutorialKey)
            
            // Also save to server
            Task {
                await saveTutorialStatusToServer()
            }
        }
    }
    
    /// Check if the user should start the tutorial
    /// This should be called when user reaches the main feed for the first time
    private func shouldStartTutorial() -> Bool {
        // Check if user has completed onboarding and this is their first time in the main app
		guard UserAuthViewModel.shared.spawnUser != nil else { return false }
        
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
            // During activity type selection, only allow activities tab
            return tab == .activities
        case .activityCreation:
            // During activity creation, allow all tabs (user can navigate away)
            return true
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
    
    // MARK: - Server Sync Methods
    
    /// Fetch tutorial completion status from server
    @MainActor
    private func fetchTutorialStatusFromServer() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("🎯 TutorialViewModel: Cannot fetch tutorial status - no user logged in")
            return
        }
        
        // Skip server check in mock mode
        if MockAPIService.isMocking {
            print("🎯 TutorialViewModel: Skipping server check in mock mode")
            return
        }
        
        do {
            if let url = URL(string: "\(APIService.baseURL)users/preferences/\(userId)") {
                let preferences: UserPreferencesDTO = try await apiService.fetchData(
                    from: url,
                    parameters: nil
                )
                
                if preferences.hasCompletedTutorial {
                    print("🎯 TutorialViewModel: Server indicates tutorial completed - updating local state")
                    userDefaults.set(true, forKey: hasCompletedTutorialKey)
                    tutorialState = .completed
                    shouldShowCallout = false
                }
            }
        } catch {
            print("🎯 TutorialViewModel: Failed to fetch tutorial status from server: \(error)")
            // Continue with local logic if server fails
        }
    }
    
    /// Save tutorial completion status to server
    private func saveTutorialStatusToServer() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("🎯 TutorialViewModel: Cannot save tutorial status - no user logged in")
            return
        }
        
        // Skip server update in mock mode
        if MockAPIService.isMocking {
            print("🎯 TutorialViewModel: Skipping server update in mock mode")
            return
        }
        
        let preferences = UserPreferencesDTO(
            hasCompletedTutorial: true,
            userId: userId
        )
        
        do {
            if let url = URL(string: "\(APIService.baseURL)users/preferences/\(userId)") {
                let _: UserPreferencesDTO? = try await apiService.sendData(
                    preferences,
                    to: url,
                    parameters: nil
                )
                print("🎯 TutorialViewModel: Successfully saved tutorial completion to server")
            }
        } catch {
            print("🎯 TutorialViewModel: Failed to save tutorial status to server: \(error)")
            // Local storage is already updated, so this is not critical
        }
    }
} 
