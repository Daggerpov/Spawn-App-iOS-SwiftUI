//
//  TutorialViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 1/21/25.
//

import Foundation
import SwiftUI

@MainActor
class TutorialViewModel: ObservableObject {
	static let shared = TutorialViewModel()

	@Published var tutorialState: TutorialState = .notStarted
	@Published var shouldShowCallout: Bool = false

	private let userDefaults = UserDefaults.standard
	private let tutorialStateKey = "TutorialState"
	private let hasCompletedTutorialKey = "HasCompletedFirstActivityTutorial"
	private let dataService: DataService

	private init() {
		self.dataService = DataService.shared
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
		guard let user = UserAuthViewModel.shared.spawnUser else { return false }

		// First check: If backend says user has completed onboarding, skip tutorial
		if let backendOnboardingStatus = user.hasCompletedOnboarding, backendOnboardingStatus {
			return false
		}

		// Check if this user has any existing activities or friends
		// If they do, they're likely an existing user who shouldn't see the tutorial
		// Note: This is checked synchronously during init, so we'll use a simpler approach
		// In practice, the backend onboarding flag is the more reliable indicator
		// This is just an extra safeguard for edge cases

		// For users who signed in with email/username (not OAuth registration),
		// they are definitely existing users and should skip tutorial
		if UserAuthViewModel.shared.authProvider == .email {
			return false
		}

		// IMPORTANT: For existing users signing into their account on a new device,
		// we should NOT show the tutorial even if they have no cached data yet.
		// The key indicator is that they already have a Spawn account that existed before this session.
		// Since we can't easily distinguish between new registrations and existing sign-ins at this point,
		// we'll be conservative and skip the tutorial for most cases to avoid annoying existing users.

		// Only show tutorial if user has explicitly never completed it AND
		// this appears to be a completely new user experience AND
		// the backend doesn't indicate they've completed onboarding
		let hasNeverCompletedTutorial = !userDefaults.bool(forKey: hasCompletedTutorialKey)
		let hasCompletedOnboarding = UserAuthViewModel.shared.hasCompletedOnboarding
		let backendOnboardingStatus = user.hasCompletedOnboarding ?? false

		// Don't show tutorial if backend says they've completed onboarding
		let shouldStart = hasNeverCompletedTutorial && hasCompletedOnboarding && !backendOnboardingStatus
		return shouldStart
	}

	/// Start the tutorial from the beginning
	func startTutorial() {
		tutorialState = .activityTypeSelection
		shouldShowCallout = true
	}

	/// Progress to activity creation step
	func progressToActivityCreation(activityType: String) {
		tutorialState = .activityCreation(selectedActivityType: activityType)
		shouldShowCallout = false
	}

	/// Complete the tutorial
	func completeTutorial() {
		tutorialState = .completed
		shouldShowCallout = false
		saveTutorialState()
	}

	/// Reset tutorial state (for testing/debugging)
	func resetTutorial() {
		tutorialState = .notStarted
		shouldShowCallout = false
		userDefaults.removeObject(forKey: hasCompletedTutorialKey)
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
		// This is a synchronous check, so we'll return false to be conservative
		// In practice, the tutorial flow should rely on backend state rather than cache checks
		return false
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
	private func fetchTutorialStatusFromServer() async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			return
		}

		// Skip server check in mock mode
		if MockAPIService.isMocking {
			return
		}

		// Use DataService to fetch user profile info
		let result: DataResult<BaseUserDTO> = await dataService.read(
			.profileInfo(userId: userId, requestingUserId: nil),
			cachePolicy: .apiOnly
		)

		switch result {
		case .success(let user, _):
			// Check if user has completed onboarding (which indicates they've used the app before)
			// If they have, we should skip the tutorial
			if let hasCompletedOnboarding = user.hasCompletedOnboarding, hasCompletedOnboarding {
				userDefaults.set(true, forKey: hasCompletedTutorialKey)
				tutorialState = .completed
				shouldShowCallout = false
			}

		case .failure:
			// Continue with local logic if server fails
			break
		}
	}

	/// Save tutorial completion status to server
	/// Note: Tutorial completion is automatically handled when the user creates their first activity,
	/// which sets hasCompletedOnboarding to true on the backend. No separate API call needed.
	private func saveTutorialStatusToServer() async {
		guard (UserAuthViewModel.shared.spawnUser?.id) != nil else {
			return
		}

		// Skip server update in mock mode
		if MockAPIService.isMocking {
			return
		}

		// The tutorial completion is actually handled automatically when the user creates their first activity
		// The backend sets hasCompletedOnboarding to true, which we use to determine tutorial status
		// So we don't need to make a separate API call here
	}
}
