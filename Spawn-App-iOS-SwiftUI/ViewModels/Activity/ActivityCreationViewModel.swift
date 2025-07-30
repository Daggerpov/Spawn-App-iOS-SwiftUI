//
//  ActivityCreationViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import Foundation
import Combine


class ActivityCreationViewModel: ObservableObject {
	// semi-singleton, that can only be reset upon calling `reInitialize()`
	static var shared: ActivityCreationViewModel = ActivityCreationViewModel()

	@Published var selectedDate: Date = Date()
	@Published var activity: ActivityDTO
	@Published var creationMessage: String = ""
	@Published var selectedActivityType: ActivityTypeDTO?
	@Published var selectedDuration: ActivityDuration = .indefinite
	@Published var selectedLocation: LocationDTO?

	@Published var selectedFriends: [FullFriendUserDTO] = []
	
	// Validation properties
	@Published var isTitleValid: Bool = true
	@Published var isInvitesValid: Bool = true
	@Published var isLocationValid: Bool = true
	@Published var isFormValid: Bool = false
	
	// Loading state
	@Published var isCreatingActivity: Bool = false
	
	// Edit state
	@Published var isEditingExistingActivity: Bool = false
	
	// MARK: - Change Tracking Properties
	// Store original values when editing starts to detect changes
	@Published var originalTitle: String?
	@Published var originalDate: Date?
	@Published var originalDuration: ActivityDuration?
	@Published var originalLocation: LocationDTO?
	
	// Computed property to check if there are any changes
	var hasAnyChanges: Bool {
		guard isEditingExistingActivity else { return false }
		
		return titleChanged || dateChanged || durationChanged || locationChanged
	}
	
	// Individual change detection properties
	var titleChanged: Bool {
		guard isEditingExistingActivity else { return false }
		return (activity.title?.trimmingCharacters(in: .whitespaces) ?? "") != (originalTitle?.trimmingCharacters(in: .whitespaces) ?? "")
	}
	
	var dateChanged: Bool {
		guard isEditingExistingActivity else { return false }
		guard let originalDate = originalDate else { return false }
		
		// Compare dates with minute precision (ignore seconds)
		let calendar = Calendar.current
		let originalComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: originalDate)
		let currentComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: selectedDate)
		
		return originalComponents != currentComponents
	}
	
	var durationChanged: Bool {
		guard isEditingExistingActivity else { return false }
		return selectedDuration != originalDuration
	}
	
	var locationChanged: Bool {
		guard isEditingExistingActivity else { return false }
		
		// Compare location names and coordinates
		if originalLocation == nil && selectedLocation == nil {
			return false
		}
		
		if originalLocation == nil || selectedLocation == nil {
			return true
		}
		
		guard let original = originalLocation, let current = selectedLocation else {
			return true
		}
		
		return original.name != current.name || 
			   abs(original.latitude - current.latitude) > 0.0001 ||
			   abs(original.longitude - current.longitude) > 0.0001
	}
	
	// MARK: - Change Summary Methods
	func getChangedFieldsSummary() -> [String] {
		var changes: [String] = []
		
		if titleChanged {
			let newTitle = activity.title?.trimmingCharacters(in: .whitespaces) ?? ""
			let oldTitle = originalTitle?.trimmingCharacters(in: .whitespaces) ?? ""
			changes.append("Title: \"\(oldTitle)\" → \"\(newTitle)\"")
		}
		
		if dateChanged {
			let formatter = DateFormatter()
			formatter.dateFormat = "MMM d, h:mm a"
			let oldDateStr = originalDate.map { formatter.string(from: $0) } ?? ""
			let newDateStr = formatter.string(from: selectedDate)
			changes.append("Date & Time: \(oldDateStr) → \(newDateStr)")
		}
		
		if durationChanged {
			let oldDuration = originalDuration?.title ?? "Indefinite"
			let newDuration = selectedDuration.title
			changes.append("Duration: \(oldDuration) → \(newDuration)")
		}
		
		if locationChanged {
			let oldLocation = originalLocation?.name ?? "No location"
			let newLocation = selectedLocation?.name ?? "No location"
			changes.append("Location: \(oldLocation) → \(newLocation)")
		}
		
		return changes
	}
	
	func getChangesSummaryText() -> String {
		let changes = getChangedFieldsSummary()
		if changes.isEmpty {
			return "No changes to save."
		} else if changes.count == 1 {
			// Add safety check to prevent force unwrapping crash
			return "1 change: \(changes.first ?? "Unknown change")"
		} else {
			return "\(changes.count) changes:\n" + changes.joined(separator: "\n")
		}
	}
	
	// MARK: - Reset Changes Method
	func resetToOriginalValues() {
		guard isEditingExistingActivity else { return }
		
		activity.title = originalTitle
		selectedDate = originalDate ?? Date()
		selectedDuration = originalDuration ?? .indefinite
		selectedLocation = originalLocation
	}
	
	private var apiService: IAPIService
	
	public static func reInitialize() {
		shared.resetToDefaults()
	}
	
	// Method to pre-select an activity type (e.g., when coming from feed view)
	public static func initializeWithSelectedActivityType(_ activityTypeDTO: ActivityTypeDTO?) {
		// Instead of creating a new instance, reset the existing one and set the type
		shared.resetToDefaults()
		shared.selectedActivityType = activityTypeDTO
	}
	
	// Method to initialize with existing activity data for editing
	public static func initializeWithExistingActivity(_ activity: FullFeedActivityDTO) {
		shared.resetToDefaults()
		shared.isEditingExistingActivity = true
		
		// Populate the view model with existing activity data
		shared.activity.id = activity.id
		shared.activity.title = activity.title ?? ""
		shared.activity.startTime = activity.startTime ?? Date()
		shared.activity.endTime = activity.endTime ?? Date().addingTimeInterval(2 * 60 * 60)
		shared.activity.location = activity.location
		shared.activity.icon = activity.icon ?? "⭐️"
		shared.activity.creatorUserId = activity.creatorUser.id
		
		// Set view model properties
		shared.selectedDate = activity.startTime ?? Date()
		shared.selectedLocation = activity.location
		
		// Calculate duration based on start and end times
		if let startTime = activity.startTime, let endTime = activity.endTime {
			let duration = endTime.timeIntervalSince(startTime)
			if duration <= 30 * 60 { // 30 minutes
				shared.selectedDuration = .thirtyMinutes
			} else if duration <= 60 * 60 { // 1 hour
				shared.selectedDuration = .oneHour
			} else if duration <= 2 * 60 * 60 { // 2 hours
				shared.selectedDuration = .twoHours
			} else {
				shared.selectedDuration = .indefinite
			}
		}
		
		// MARK: - Store Original Values for Change Tracking
		shared.originalTitle = activity.title
		shared.originalDate = activity.startTime
		shared.originalLocation = activity.location
		shared.originalDuration = shared.selectedDuration
		
		// Get activity type if available
		if let activityTypeId = activity.activityTypeId {
			// Try to find the activity type in cache
			if let activityType = AppCache.shared.activityTypes.first(where: { $0.id == activityTypeId }) {
				shared.selectedActivityType = activityType
			}
		}
		
		// Set invited friends based on activity participants
		if let participants = activity.participantUsers {
			// Filter out the creator from participants to get invited friends
			let invitedFriends = participants.compactMap { participant -> FullFriendUserDTO? in
				if participant.id != activity.creatorUser.id {
					return FullFriendUserDTO(
						id: participant.id,
						username: participant.username,
						profilePicture: participant.profilePicture,
						name: participant.name,
						bio: participant.bio,
						email: participant.email
					)
				}
				return nil
			}
			shared.selectedFriends = invitedFriends
		}
		
		// Also include originally invited users who might not be participants yet
		if let invitedUsers = activity.invitedUsers {
			let additionalInvitedFriends = invitedUsers.compactMap { invitedUser -> FullFriendUserDTO? in
				// Only add if not already in selectedFriends
				if !shared.selectedFriends.contains(where: { $0.id == invitedUser.id }) && invitedUser.id != activity.creatorUser.id {
					return FullFriendUserDTO(
						id: invitedUser.id,
						username: invitedUser.username,
						profilePicture: invitedUser.profilePicture,
						name: invitedUser.name,
						bio: invitedUser.bio,
						email: invitedUser.email
					)
				}
				return nil
			}
			shared.selectedFriends.append(contentsOf: additionalInvitedFriends)
		}
	}
	
	// Helper method to reset the current instance to defaults
	private func resetToDefaults() {
		
		// Reset all properties to their default values
		selectedDate = Date()
		creationMessage = ""
		selectedActivityType = nil
		selectedDuration = .indefinite
		selectedLocation = nil
		selectedFriends = []
		isTitleValid = true
		isInvitesValid = true
		isLocationValid = true
		isFormValid = false
		isCreatingActivity = false
		isEditingExistingActivity = false
		
		// Reset change tracking properties
		originalTitle = nil
		originalDate = nil
		originalDuration = nil
		originalLocation = nil
		
		// Reset the activity DTO
		let defaultStart = Date()
		let defaultEnd = Date().addingTimeInterval(2 * 60 * 60)  // 2 hours later
		activity = ActivityDTO(
			id: UUID(),
			title: "",
			startTime: defaultStart,
			endTime: defaultEnd,
			icon: "⭐️",
			creatorUserId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
			invitedUserIds: []
		)
		
		// Reload friends
		loadAllFriendsAsSelected()
	}
	
	// Force reset method for debugging
	public static func forceReset() {
		shared.selectedActivityType = nil
	}

	// Private initializer to enforce singleton pattern
	private init() {
		self.apiService =
			MockAPIService.isMocking
			? MockAPIService(
				userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())
			: APIService()

		let defaultStart = Date()
		let defaultEnd = Date().addingTimeInterval(2 * 60 * 60)  // 2 hours later
		self.activity = ActivityDTO(
			id: UUID(),
			title: "",
			startTime: defaultStart,
			endTime: defaultEnd,
			icon: "⭐️",
			creatorUserId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
			invitedUserIds: []
		)
		
		// Ensure selectedActivityType starts as nil by default (no auto-selection)
		self.selectedActivityType = nil
		
		// Automatically populate friends when initializing
		loadAllFriendsAsSelected()
	}
	
	// Load all friends and automatically select them for invitation
	private func loadAllFriendsAsSelected() {
		Task {
			await loadAllFriends()
		}
	}
	
	// Load all friends from cache or API
	private func loadAllFriends() async {
		do {
					// Try to get friends from cache first
		let cachedFriends = AppCache.shared.getCurrentUserFriends()
		if !cachedFriends.isEmpty {
			await MainActor.run {
				selectedFriends = cachedFriends
			}
			return
		}
			
			// If cache is empty, fetch from API
			guard let url = URL(string: APIService.baseURL + "users/friends/\(UserAuthViewModel.shared.spawnUser?.id ?? UUID())") else {
				await MainActor.run {
					selectedFriends = []
				}
				return
			}
			
			let friends: [FullFriendUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
			await MainActor.run {
				selectedFriends = friends
			}
		} catch {
			print("Error loading friends: \(error)")
			await MainActor.run {
				selectedFriends = []
			}
		}
	}
	
	// Method to add a friend to the selected friends list
	func addFriend(_ friend: FullFriendUserDTO) {
		DispatchQueue.main.async {
			if !self.selectedFriends.contains(where: { $0.id == friend.id }) {
				self.selectedFriends.append(friend)
			}
		}
	}
	
	// Method to remove a friend from the selected friends list
	func removeFriend(_ friend: FullFriendUserDTO) {
		DispatchQueue.main.async {
			self.selectedFriends.removeAll { $0.id == friend.id }
		}
	}
	
	// Method to toggle a friend's selection
	func toggleFriendSelection(_ friend: FullFriendUserDTO) {
		DispatchQueue.main.async {
			if self.selectedFriends.contains(where: { $0.id == friend.id }) {
				self.selectedFriends.removeAll { $0.id == friend.id }
			} else if !self.selectedFriends.contains(where: { $0.id == friend.id }) {
				self.selectedFriends.append(friend)
			}
		}
	}
	
	// Method to check if a friend is selected
	func isFriendSelected(_ friend: FullFriendUserDTO) -> Bool {
		return selectedFriends.contains(where: { $0.id == friend.id })
	}

	func validateActivityForm() async {
        // Check title
        let trimmedTitle = activity.title?.trimmingCharacters(in: .whitespaces) ?? ""
        print("🔍 DEBUG: Validating form...")
        print("🔍 DEBUG: - Raw title: '\(activity.title ?? "nil")'")
        print("🔍 DEBUG: - Trimmed title: '\(trimmedTitle)'")
        print("🔍 DEBUG: - Title is empty: \(trimmedTitle.isEmpty)")
        
        await MainActor.run {
            isTitleValid = !trimmedTitle.isEmpty
            print("🔍 DEBUG: - Title valid result: \(isTitleValid)")
            
            // Invites are optional - users can create activities without inviting anyone
            isInvitesValid = true
            print("🔍 DEBUG: - Selected friends count: \(selectedFriends.count)")
            print("🔍 DEBUG: - Invites valid result: \(isInvitesValid)")
            
            // Check if location is valid
            let hasLocation = activity.location != nil
            let hasLocationName = activity.location?.name.trimmingCharacters(in: .whitespaces).isEmpty == false
            let hasCoordinates = (activity.location?.latitude != 0 || activity.location?.longitude != 0)
            
            print("🔍 DEBUG: - Has location: \(hasLocation)")
            print("🔍 DEBUG: - Has location name: \(hasLocationName)")
            print("🔍 DEBUG: - Has coordinates: \(hasCoordinates)")
            
            isLocationValid = hasLocation && hasLocationName && hasCoordinates
            print("🔍 DEBUG: - Location valid result: \(isLocationValid)")
            
            // Update overall form validity
            isFormValid = isTitleValid && isInvitesValid && isLocationValid
            print("🔍 DEBUG: - Overall form valid: \(isFormValid)")
        }
	}

	func updateActivityDuration() {
		let startTime = selectedDate
		let endTime: Date?
		
		switch selectedDuration {
		case .indefinite:
			endTime = nil // Set to nil for indefinite duration
		case .twoHours:
			endTime = Calendar.current.date(byAdding: .hour, value: 2, to: startTime) ?? startTime
		case .oneHour:
			endTime = Calendar.current.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
		case .thirtyMinutes:
			endTime = Calendar.current.date(byAdding: .minute, value: 30, to: startTime) ?? startTime
		}
		
		activity.startTime = startTime
		activity.endTime = endTime
	}
	
	func updateActivityType() {
		guard let activityTypeDTO = selectedActivityType else { return }
		
		// Don't overwrite the user's custom title with the activity type name
		// Only set icon based on the selected activity type
		activity.icon = activityTypeDTO.icon
		
		// Category is now handled by the back-end, so we don't need to infer it
	}
	
	func setLocation(_ location: LocationDTO) {
		selectedLocation = location
		activity.location = location
	}

	func createActivity() async {
		// Check if activity creation is already in progress
		if isCreatingActivity {
			print("🔍 DEBUG: Activity creation already in progress, returning early")
			return
		}

		print("🔍 DEBUG: Starting activity creation process")
		await MainActor.run {
			isCreatingActivity = true
		}

		// Map selected friends to their IDs
		activity.invitedUserIds = selectedFriends.map { $0.id }
		print("🔍 DEBUG: Selected friends count: \(selectedFriends.count)")
		
		// Update the activity with the current date and duration
		updateActivityDuration()
		updateActivityType()
		
		print("🔍 DEBUG: Activity title: '\(activity.title ?? "nil")'")
		print("🔍 DEBUG: Activity location: \(activity.location?.name ?? "nil")")
		print("🔍 DEBUG: Activity location coordinates: \(activity.location?.latitude ?? 0), \(activity.location?.longitude ?? 0)")
		print("🔍 DEBUG: Selected activity type: \(selectedActivityType?.title ?? "nil")")
		
		// Validate form before creating
		await validateActivityForm()
		
		print("🔍 DEBUG: Form validation results:")
		print("🔍 DEBUG: - Title valid: \(isTitleValid)")
		print("🔍 DEBUG: - Invites valid: \(isInvitesValid)")
		print("🔍 DEBUG: - Location valid: \(isLocationValid)")
		print("🔍 DEBUG: - Overall form valid: \(isFormValid)")
		
		guard isFormValid else {
			print("🔍 DEBUG: Form validation failed, not making API call")
			await MainActor.run {
				isCreatingActivity = false
			}
			return
		}
		
		print("🔍 DEBUG: Form validation passed, making API call")
		
		do {
			guard let url = URL(string: APIService.baseURL + "activities") else {
				print("🔍 DEBUG: Invalid URL construction")
				await MainActor.run {
					creationMessage = "Failed to create activity. Invalid URL."
				}
				isCreatingActivity = false
				return
			}
			
			print("🔍 DEBUG: Making API call to: \(url.absoluteString)")
			print("🔍 DEBUG: Using MockAPIService.isMocking: \(MockAPIService.isMocking)")
			
			let createdActivity: FullFeedActivityDTO? = try await apiService.sendData(activity, to: url, parameters: nil)
			
			print("🔍 DEBUG: API call completed")
			print("🔍 DEBUG: Created activity: \(createdActivity != nil ? "success" : "nil")")
			
			if let createdActivity = createdActivity {
				// Cache the created activity
				AppCache.shared.addOrUpdateActivity(createdActivity)
				
				// Post notification for successful creation
				NotificationCenter.default.post(
					name: .activityCreated,
					object: createdActivity
				)
				
				await MainActor.run {
					creationMessage = "Activity created successfully!"
				}
				print("🔍 DEBUG: Activity creation successful")
			} else {
				await MainActor.run {
					creationMessage = "Failed to create activity. Please try again."
				}
				print("🔍 DEBUG: Activity creation failed - received nil response")
			}
			
		} catch {
			print("🔍 DEBUG: API call threw error: \(error)")
			await MainActor.run {
				creationMessage = "Failed to create activity. Please try again."
			}
		}
		
		await MainActor.run {
			isCreatingActivity = false
		}
	}
	
	func updateActivity() async {
		// Check if activity update is already in progress
		if isCreatingActivity {
			return
		}

		await MainActor.run {
			isCreatingActivity = true
		}

		// Map selected friends to their IDs
		activity.invitedUserIds = selectedFriends.map { $0.id }
		
		// Update the activity with the current date and duration
		updateActivityDuration()
		updateActivityType()
		
		// Validate form before updating
		await validateActivityForm()
		
		guard isFormValid else {
			isCreatingActivity = false
			return
		}
		
		do {
			guard let url = URL(string: APIService.baseURL + "activities/\(activity.id)") else {
				await MainActor.run {
					creationMessage = "Failed to update activity. Invalid URL."
				}
				isCreatingActivity = false
				return
			}
			
			let updatedActivity: FullFeedActivityDTO? = try await apiService.updateData(activity, to: url, parameters: nil)
			
			if let updatedActivity = updatedActivity {
				await MainActor.run {
					// Cache the updated activity first
					AppCache.shared.addOrUpdateActivity(updatedActivity)
					
					// Add a small delay to ensure cache update completes before posting notification
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
						// Post notification for successful update after cache is updated
						NotificationCenter.default.post(
							name: .activityUpdated,
							object: updatedActivity
						)
					}
					
					creationMessage = "Activity updated successfully!"
				}
			} else {
				await MainActor.run {
					creationMessage = "Failed to update activity. Please try again."
				}
			}
			
		} catch {
			print("Error updating activity: \(error)")
			await MainActor.run {
				creationMessage = "Failed to update activity. Please try again."
			}
		}
		
		await MainActor.run {
			isCreatingActivity = false
		}
	}
}

// MARK: - Helper Extensions

// ActivityType enum extension removed - now using ActivityTypeDTO directly 
