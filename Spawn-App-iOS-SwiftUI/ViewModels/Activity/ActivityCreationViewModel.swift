//
//  ActivityCreationViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import Foundation

@Observable
@MainActor
final class ActivityCreationViewModel {
	// semi-singleton, that can only be reset upon calling `reInitialize()`
	static var shared: ActivityCreationViewModel = ActivityCreationViewModel()

	var selectedDate: Date = Date()
	var activity: ActivityDTO
	var creationMessage: String = ""
	var timeValidationMessage: String = ""
	var selectedActivityType: ActivityTypeDTO?
	var selectedDuration: ActivityDuration = .indefinite
	var selectedLocation: LocationDTO?

	/// Selected friends for activity invitation (uses MinimalFriendDTO to reduce memory usage)
	var selectedFriends: [MinimalFriendDTO] = []

	// MARK: - Constants
	private enum TimeConstants {
		static let twoHoursInSeconds: TimeInterval = 2 * 60 * 60
		static let oneHourInSeconds: TimeInterval = 60 * 60
		static let thirtyMinutesInSeconds: TimeInterval = 30 * 60
		static let coordinateTolerance: Double = 0.0001
	}

	// Validation properties
	var isTitleValid: Bool = true
	var isInvitesValid: Bool = true
	var isLocationValid: Bool = true
	var isTimeValid: Bool = true
	var isFormValid: Bool = false

	// Loading state
	var isCreatingActivity: Bool = false

	// Guard to prevent redundant friend loading
	private var isLoadingFriends: Bool = false

	// Error notification service
	private let errorNotificationService = ErrorNotificationService.shared

	// Edit state
	var isEditingExistingActivity: Bool = false

	// UI state for controlling navigation bar visibility
	var isOnLocationSelectionStep: Bool = false

	// MARK: - Change Tracking Properties
	// Store original values when editing starts to detect changes
	var originalTitle: String?
	var originalDate: Date?
	var originalDuration: ActivityDuration?
	var originalLocation: LocationDTO?

	// Computed property to check if there are any changes
	var hasAnyChanges: Bool {
		guard isEditingExistingActivity else { return false }

		return titleChanged || dateChanged || durationChanged || locationChanged
	}

	// Individual change detection properties
	var titleChanged: Bool {
		guard isEditingExistingActivity else { return false }
		return (activity.title?.trimmingCharacters(in: .whitespaces) ?? "")
			!= (originalTitle?.trimmingCharacters(in: .whitespaces) ?? "")
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

		return original.name != current.name
			|| abs(original.latitude - current.latitude) > TimeConstants.coordinateTolerance
			|| abs(original.longitude - current.longitude) > TimeConstants.coordinateTolerance
	}

	// MARK: - Reset Changes Method
	func resetToOriginalValues() {
		guard isEditingExistingActivity else { return }

		activity.title = originalTitle
		selectedDate = originalDate ?? Date()
		selectedDuration = originalDuration ?? .indefinite
		selectedLocation = originalLocation
	}

	private var dataService: DataService

	public static func reInitialize() {
		shared.resetToDefaults()
	}

	// Method to pre-select an activity type (e.g., when coming from feed view)
	public static func initializeWithSelectedActivityType(_ activityTypeDTO: ActivityTypeDTO?) {
		// Instead of creating a new instance, reset the existing one and set the type
		shared.resetToDefaults()
		shared.selectedActivityType = activityTypeDTO

		// If activity type is selected, filter friends to only those in the activity type
		if let activityType = activityTypeDTO {
			shared.filterFriendsToActivityType(activityType)
		}
	}

	/// Filter selectedFriends to only include friends from the activity type's associatedFriends
	private func filterFriendsToActivityType(_ activityType: ActivityTypeDTO) {
		let activityTypeFriendIds = Set(activityType.associatedFriends.map { $0.id })
		selectedFriends = selectedFriends.filter { activityTypeFriendIds.contains($0.id) }
	}

	/// Called when user selects/changes an activity type via the UI
	/// Filters friends to only those in the activity type, or reloads all friends if deselected
	func onActivityTypeChanged() {
		if let activityType = selectedActivityType {
			filterFriendsToActivityType(activityType)
		} else {
			// If activity type was deselected, reload all friends
			loadAllFriendsAsSelected()
		}
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
			shared.selectedDuration = calculateDuration(from: startTime, to: endTime)
		}

		// MARK: - Store Original Values for Change Tracking
		shared.originalTitle = activity.title
		shared.originalDate = activity.startTime
		shared.originalLocation = activity.location
		shared.originalDuration = shared.selectedDuration

		// Get activity type if available
		if let activityTypeId = activity.activityTypeId {
			// Try to fetch the activity type from DataService
			Task {
				guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
				let result: DataResult<[ActivityTypeDTO]> = await shared.dataService.read(
					.activityTypes(userId: userId),
					cachePolicy: .cacheOnly
				)

				if case .success(let types, _) = result,
					let activityType = types.first(where: { $0.id == activityTypeId })
				{
					await MainActor.run {
						shared.selectedActivityType = activityType
					}
				}
			}
		}

		// Set invited friends from participants and invited users
		shared.selectedFriends = extractInvitedFriends(
			from: activity,
			participants: activity.participantUsers,
			invitedUsers: activity.invitedUsers
		)
	}

	// Helper method to reset the current instance to defaults
	private func resetToDefaults() {

		// Reset all properties to their default values
		selectedDate = Date()
		creationMessage = ""
		timeValidationMessage = ""
		selectedActivityType = nil
		selectedDuration = .indefinite
		selectedLocation = nil
		selectedFriends = []
		isTitleValid = true
		isInvitesValid = true
		isLocationValid = true
		isTimeValid = true
		isFormValid = false
		isCreatingActivity = false
		isEditingExistingActivity = false
		isLoadingFriends = false

		// Reset change tracking properties
		originalTitle = nil
		originalDate = nil
		originalDuration = nil
		originalLocation = nil

		// Reset the activity DTO
		activity = Self.createDefaultActivity()

		// Reload friends
		loadAllFriendsAsSelected()
	}

	// Force reset method for debugging
	public static func forceReset() {
		shared.selectedActivityType = nil
	}

	// MARK: - Initialization

	/// Create a default activity DTO
	public static func createDefaultActivity() -> ActivityDTO {
		let defaultStart = Date()
		let defaultEnd = Date().addingTimeInterval(TimeConstants.twoHoursInSeconds)
		return ActivityDTO(
			id: UUID(),
			title: "",
			startTime: defaultStart,
			endTime: defaultEnd,
			icon: "⭐️",
			creatorUserId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
			invitedUserIds: []
		)
	}

	/// Private initializer to enforce singleton pattern
	private init() {
		self.dataService = DataService.shared

		self.activity = Self.createDefaultActivity()

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

	// Load all friends using DataService (uses minimal DTOs to reduce memory usage)
	private func loadAllFriends() async {
		// Guard against redundant loading - prevents infinite loops
		guard !isLoadingFriends else {
			print("🔍 DEBUG: loadAllFriends() skipped - already loading")
			return
		}

		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			await MainActor.run {
				selectedFriends = []
			}
			return
		}

		isLoadingFriends = true
		defer { isLoadingFriends = false }

		// Use DataService with cache-first policy but NO background refresh
		// Background refresh can cause feedback loops when combined with observation
		// Using minimalFriends endpoint to reduce memory usage
		let result: DataResult<[MinimalFriendDTO]> = await dataService.read(
			.minimalFriends(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: false)
		)

		switch result {
		case .success(let friends, _):
			await MainActor.run {
				// If an activity type is already selected, filter friends to only those in the activity type
				if let activityType = selectedActivityType {
					let activityTypeFriendIds = Set(activityType.associatedFriends.map { $0.id })
					selectedFriends = friends.filter { activityTypeFriendIds.contains($0.id) }
				} else {
					selectedFriends = friends
				}
			}

		case .failure(let error):
			print("Error loading friends: \(ErrorFormattingService.shared.formatError(error))")
			await MainActor.run {
				selectedFriends = []
			}
		}
	}

	// MARK: - Helper Methods

	/// Calculate duration from time interval
	private static func calculateDuration(from startTime: Date, to endTime: Date) -> ActivityDuration {
		let duration = endTime.timeIntervalSince(startTime)
		if duration <= TimeConstants.thirtyMinutesInSeconds {
			return .thirtyMinutes
		} else if duration <= TimeConstants.oneHourInSeconds {
			return .oneHour
		} else if duration <= TimeConstants.twoHoursInSeconds {
			return .twoHours
		} else {
			return .indefinite
		}
	}

	/// Convert BaseUserDTO to MinimalFriendDTO (drops bio and email to save memory)
	private static func convertToFriendDTO(_ user: BaseUserDTO) -> MinimalFriendDTO {
		return MinimalFriendDTO(
			id: user.id,
			username: user.username,
			name: user.name,
			profilePicture: user.profilePicture
		)
	}

	/// Extract invited friends from activity participants and invited users
	private static func extractInvitedFriends(
		from activity: FullFeedActivityDTO,
		participants: [BaseUserDTO]?,
		invitedUsers: [BaseUserDTO]?
	) -> [MinimalFriendDTO] {
		var friends: [MinimalFriendDTO] = []
		let creatorId = activity.creatorUser.id

		// Add participants (excluding creator)
		if let participants = participants {
			let participantFriends =
				participants
				.filter { $0.id != creatorId }
				.map { convertToFriendDTO($0) }
			friends.append(contentsOf: participantFriends)
		}

		// Add invited users (excluding creator and duplicates)
		if let invitedUsers = invitedUsers {
			let additionalFriends =
				invitedUsers
				.filter { $0.id != creatorId && !friends.contains(where: { $0.id == $0.id }) }
				.map { convertToFriendDTO($0) }
			friends.append(contentsOf: additionalFriends)
		}

		return friends
	}

	// MARK: - Friend Selection Helpers

	/// Helper to execute friend selection changes
	private func updateSelectedFriends(_ update: () -> Void) {
		update()
	}

	/// Check if a friend is selected
	func isFriendSelected(_ friend: MinimalFriendDTO) -> Bool {
		return selectedFriends.contains(where: { $0.id == friend.id })
	}

	/// Add a friend to the selected friends list
	func addFriend(_ friend: MinimalFriendDTO) {
		updateSelectedFriends { [weak self] in
			guard let self = self, !self.isFriendSelected(friend) else { return }
			self.selectedFriends.append(friend)
		}
	}

	/// Remove a friend from the selected friends list
	func removeFriend(_ friend: MinimalFriendDTO) {
		updateSelectedFriends { [weak self] in
			self?.selectedFriends.removeAll { $0.id == friend.id }
		}
	}

	/// Toggle a friend's selection
	func toggleFriendSelection(_ friend: MinimalFriendDTO) {
		updateSelectedFriends { [weak self] in
			guard let self = self else { return }
			if self.isFriendSelected(friend) {
				self.selectedFriends.removeAll { $0.id == friend.id }
			} else {
				self.selectedFriends.append(friend)
			}
		}
	}

	func validateActivityForm() async {
		// Check title
		let trimmedTitle = activity.title?.trimmingCharacters(in: .whitespaces) ?? ""
		print("🔍 DEBUG: Validating form...")
		print("🔍 DEBUG: - Raw title: '\(activity.title ?? "nil")'")
		print("🔍 DEBUG: - Trimmed title: '\(trimmedTitle)'")
		print("🔍 DEBUG: - Title is empty: \(trimmedTitle.isEmpty)")

		// Update activity duration to ensure end time is current
		updateActivityDuration()

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

			// Check if activity time is valid (start time and end time not in the past)
			let now = Date()
			let isStartTimeValid = activity.startTime == nil || activity.startTime! > now
			let isEndTimeValid = activity.endTime == nil || activity.endTime! > now

			print("🔍 DEBUG: - Activity start time: \(activity.startTime?.description ?? "nil")")
			print("🔍 DEBUG: - Activity end time: \(activity.endTime?.description ?? "nil")")
			print("🔍 DEBUG: - Current time: \(now.description)")
			print("🔍 DEBUG: - Start time is valid: \(isStartTimeValid)")
			print("🔍 DEBUG: - End time is valid: \(isEndTimeValid)")

			isTimeValid = isStartTimeValid && isEndTimeValid

			// Set time validation message
			if !isStartTimeValid && !isEndTimeValid {
				timeValidationMessage = "Activity cannot start or end in the past. Please select a future time."
			} else if !isStartTimeValid {
				timeValidationMessage = "Activity cannot start in the past. Please select a future time."
			} else if !isEndTimeValid {
				timeValidationMessage = "Activity cannot end in the past. Please select a future time."
			} else {
				timeValidationMessage = ""
			}

			// Update overall form validity
			isFormValid = isTitleValid && isInvitesValid && isLocationValid && isTimeValid
			print("🔍 DEBUG: - Overall form valid: \(isFormValid)")
		}
	}

	func updateActivityDuration() {
		let startTime = selectedDate
		let endTime: Date?

		switch selectedDuration {
		case .indefinite:
			endTime = nil  // Set to nil for indefinite duration
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

	// MARK: - Activity Creation & Update

	/// Prepare activity for creation or update
	private func prepareActivity() {
		activity.invitedUserIds = selectedFriends.map { $0.id }
		activity.clientTimezone = TimeZone.current.identifier
		updateActivityDuration()
		updateActivityType()
	}

	/// Set creation message on main actor
	private func setCreationMessage(_ message: String) async {
		await MainActor.run {
			creationMessage = message
		}
	}

	/// Set loading state on main actor
	private func setLoadingState(_ isLoading: Bool) async {
		await MainActor.run {
			isCreatingActivity = isLoading
		}
	}

	func createActivity() async {
		// Check if activity creation is already in progress
		guard !isCreatingActivity else {
			print("🔍 DEBUG: Activity creation already in progress, returning early")
			return
		}

		print("🔍 DEBUG: Starting activity creation process")
		await setLoadingState(true)

		// Prepare activity data
		prepareActivity()

		print("🔍 DEBUG: Activity title: '\(activity.title ?? "nil")'")
		print("🔍 DEBUG: Selected friends count: \(selectedFriends.count)")

		// Validate form before creating
		await validateActivityForm()

		guard isFormValid else {
			print("🔍 DEBUG: Form validation failed")
			await setLoadingState(false)
			return
		}

		print("🔍 DEBUG: Form validation passed, creating activity using DataService")

		// Use DataService with WriteOperationType
		let operationType = WriteOperationType.createActivity(activity: activity)
		let result: DataResult<ActivityCreationResponseDTO> = await dataService.write(
			operationType, body: activity)

		switch result {
		case .success(let response, _):
			// Notify about successful creation
			NotificationCenter.default.post(name: .activityCreated, object: response.activity)

			await setCreationMessage("Activity created successfully!")
			print("🔍 DEBUG: Activity creation successful")

		case .failure(let error):
			print("🔍 DEBUG: Activity creation failed: \(error)")
			errorNotificationService.showError(error, resource: .activity, operation: .create)
			await setCreationMessage("Failed to create activity. Please try again.")
		}

		await setLoadingState(false)
	}

	func updateActivity() async {
		// Check if activity update is already in progress
		guard !isCreatingActivity else { return }

		await setLoadingState(true)

		// Prepare activity data
		prepareActivity()

		// Validate form before updating
		await validateActivityForm()

		guard isFormValid else {
			await setLoadingState(false)
			return
		}

		// Create partial update data
		let updateData = buildPartialUpdateData()

		// Use DataService with WriteOperationType
		let operationType = WriteOperationType.partialUpdateActivity(activityId: activity.id, update: updateData)
		let result: DataResult<FullFeedActivityDTO> = await dataService.write(
			operationType, body: updateData)

		switch result {
		case .success(let updatedActivity, _):
			await MainActor.run {
				// Notify about successful update
				NotificationCenter.default.post(name: .activityUpdated, object: updatedActivity)
				creationMessage = "Activity updated successfully!"
			}

		case .failure(let error):
			print("Error updating activity: \(error)")
			errorNotificationService.showError(error, resource: .activity, operation: .update)
			await setCreationMessage("Failed to update activity. Please try again.")
		}

		await setLoadingState(false)
	}

	/// Build partial update data for activity update
	private func buildPartialUpdateData() -> ActivityPartialUpdateDTO {
		var updateData = ActivityPartialUpdateDTO(
			title: activity.title ?? "",
			icon: activity.icon ?? "",
			startTime: nil,
			endTime: nil,
			participantLimit: nil,
			note: nil
		)

		// Add time fields if they've changed
		if dateChanged {
			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

			updateData.startTime = formatter.string(from: activity.startTime ?? Date())
			if let endTime = activity.endTime {
				updateData.endTime = formatter.string(from: endTime)
			}
		}

		// Add participant limit if set
		if let participantLimit = activity.participantLimit, participantLimit > 0 {
			updateData.participantLimit = participantLimit
		}

		// Add note if set
		if let note = activity.note, !note.isEmpty {
			updateData.note = note
		}

		return updateData
	}
}

// MARK: - Helper Extensions

// ActivityType enum extension removed - now using ActivityTypeDTO directly
