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
	@Published var activity: ActivityCreationDTO
	@Published var creationMessage: String = ""
	@Published var selectedActivityType: ActivityTypeDTO?
	@Published var selectedDuration: ActivityDuration = .indefinite
	@Published var selectedLocation: Location?

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
		
		// Reset the activity DTO
		let defaultStart = Date()
		let defaultEnd = Date().addingTimeInterval(2 * 60 * 60)  // 2 hours later
		activity = ActivityCreationDTO(
			id: UUID(),
			title: "",
			startTime: defaultStart,
			endTime: defaultEnd,
			location: nil,
			icon: "⭐️",
			creatorUserId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
			invitedFriendUserIds: []
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
		self.activity = ActivityCreationDTO(
			id: UUID(),
			title: "",
			startTime: defaultStart,
			endTime: defaultEnd,
			location: nil,
			icon: "⭐️",
			creatorUserId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
			invitedFriendUserIds: []
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
			let cachedFriends = AppCache.shared.friends
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
		if !selectedFriends.contains(where: { $0.id == friend.id }) {
			selectedFriends.append(friend)
		}
	}
	
	// Method to remove a friend from the selected friends list
	func removeFriend(_ friend: FullFriendUserDTO) {
		selectedFriends.removeAll { $0.id == friend.id }
	}
	
	// Method to toggle a friend's selection
	func toggleFriendSelection(_ friend: FullFriendUserDTO) {
		if selectedFriends.contains(where: { $0.id == friend.id }) {
			removeFriend(friend)
		} else {
			addFriend(friend)
		}
	}
	
	// Method to check if a friend is selected
	func isFriendSelected(_ friend: FullFriendUserDTO) -> Bool {
		return selectedFriends.contains(where: { $0.id == friend.id })
	}

	func validateActivityForm() async {
        // Check title
        let trimmedTitle = activity.title?.trimmingCharacters(in: .whitespaces) ?? ""
        await MainActor.run {
            isTitleValid = !trimmedTitle.isEmpty
            // Check if at least one friend is invited
            isInvitesValid = !selectedFriends.isEmpty
            // Check if location is valid
            isLocationValid = activity.location != nil && 
                             !activity.location!.name.trimmingCharacters(in: .whitespaces).isEmpty && 
                             (activity.location!.latitude != 0 || activity.location!.longitude != 0)
            
            // Update overall form validity
            isFormValid = isTitleValid && isInvitesValid && isLocationValid
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
	
	func setLocation(_ location: Location) {
		selectedLocation = location
		activity.location = location
	}

	func createActivity() async {
		// Check if activity creation is already in progress
		if isCreatingActivity {
			return
		}

		await MainActor.run {
			isCreatingActivity = true
		}

		// Map selected friends to their IDs
		activity.invitedFriendUserIds = selectedFriends.map { $0.id }
		
		// Update the activity with the current date and duration
		updateActivityDuration()
		updateActivityType()
		
		// Validate form before creating
		await validateActivityForm()
		
		guard isFormValid else {
			isCreatingActivity = false
			return
		}
		
		do {
			guard let url = URL(string: APIService.baseURL + "activities") else {
				await MainActor.run {
					creationMessage = "Failed to create activity. Invalid URL."
				}
				isCreatingActivity = false
				return
			}
			
			let createdActivity: FullFeedActivityDTO? = try await apiService.sendData(activity, to: url, parameters: nil)
			
			if let createdActivity = createdActivity {
				// Cache the created activity
				AppCache.shared.addOrUpdateActivity(createdActivity)
				
				// Post notification for successful creation
				NotificationCenter.default.post(
					name: .activityCreated,
					object: createdActivity
				)
				
				creationMessage = "Activity created successfully!"
			} else {
				creationMessage = "Failed to create activity. Please try again."
			}
			
		} catch {
			print("Error creating activity: \(error)")
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
		activity.invitedFriendUserIds = selectedFriends.map { $0.id }
		
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
				// Cache the updated activity
				AppCache.shared.addOrUpdateActivity(updatedActivity)
				
				// Post notification for successful update
				NotificationCenter.default.post(
					name: .activityUpdated,
					object: updatedActivity
				)
				
				creationMessage = "Activity updated successfully!"
			} else {
				creationMessage = "Failed to update activity. Please try again."
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
