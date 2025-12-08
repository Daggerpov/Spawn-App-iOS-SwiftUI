//
//  ActivityCacheService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-07.
//

import Combine
import Foundation
import SwiftUI

/// Cache service for activity-related data
@MainActor
final class ActivityCacheService: BaseCacheService, CacheService, ObservableObject {
	static let shared = ActivityCacheService()

	// MARK: - Cached Data
	@Published var activities: [UUID: [FullFeedActivityDTO]] = [:]
	@Published var activityTypes: [UUID: [ActivityTypeDTO]] = [:]
	@Published var upcomingActivities: [UUID: [FullFeedActivityDTO]] = [:]
	/// Calendar activities keyed by "userId_month_year" (e.g., "uuid_1_2025") or "userId_all"
	@Published var calendarActivities: [String: [CalendarActivityDTO]] = [:]

	// MARK: - Constants
	private enum CacheKeys {
		static let events = "events"
		static let activityTypes = "activityTypes"
		static let upcomingActivities = "upcomingActivities"
		static let calendarActivities = "calendarActivities"
		static let lastChecked = "activityCache_lastChecked"
	}

	// MARK: - Initialization
	private override init() {
		super.init()

		// Load from disk in the background, then update on main actor
		Task.detached { [weak self] in
			await self?.loadFromDiskAsync()
		}
	}

	// MARK: - Public Methods

	/// Get activities for the current user, filtering out expired ones
	func getCurrentUserActivities() -> [FullFeedActivityDTO] {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("⚠️ [ACTIVITY-CACHE] getCurrentUserActivities: No user ID")
			return []
		}
		let userActivities = activities[userId] ?? []

		// Filter out expired activities based on server-side expiration status
		let filteredActivities = userActivities.filter { activity in
			return activity.isExpired != true
		}

		// If we filtered out expired activities, update the cache to remove them
		if filteredActivities.count != userActivities.count {
			let expiredCount = userActivities.count - filteredActivities.count
			print("🧹 [ACTIVITY-CACHE] Filtered out \(expiredCount) expired activities")
			activities[userId] = filteredActivities
			saveToDisk()
		}

		print(
			"📦 [ACTIVITY-CACHE] getCurrentUserActivities returned \(filteredActivities.count) activities for user \(userId)"
		)
		return filteredActivities
	}

	/// Update activities for a specific user
	func updateActivitiesForUser(_ newActivities: [FullFeedActivityDTO], userId: UUID) {
		// Filter out expired activities before storing in cache
		let filteredActivities = newActivities.filter { activity in
			return activity.isExpired != true
		}

		let expiredCount = newActivities.count - filteredActivities.count
		if expiredCount > 0 {
			print("🧹 [ACTIVITY-CACHE] Filtered out \(expiredCount) expired activities before caching")
		}

		activities[userId] = filteredActivities
		setLastCheckedForUser(userId, cacheType: CacheKeys.events, date: Date())

		// Pre-assign colors for even distribution
		let activityIds = filteredActivities.map { $0.id }
		ActivityColorService.shared.assignColorsForActivities(activityIds)

		saveToDisk()

		// Preload profile pictures for activities
		if !filteredActivities.isEmpty {
			Task {
				await preloadProfilePicturesForActivities([userId: filteredActivities])
			}
		}
	}

	/// Update all activities
	func updateActivities(_ newActivities: [UUID: [FullFeedActivityDTO]]) {
		activities = newActivities

		// Update timestamp for current user
		if let userId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(userId, cacheType: CacheKeys.events, date: Date())
		}

		// Pre-assign colors for even distribution
		let activityIds = newActivities.values.flatMap { $0 }.map { $0.id }
		ActivityColorService.shared.assignColorsForActivities(activityIds)

		saveToDisk()

		// Preload profile pictures for activity creators and participants
		Task {
			await preloadProfilePicturesForActivities(newActivities)
		}
	}

	/// Refresh activities from the backend
	func refreshActivities() async {
		let startTime = Date()

		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("Cannot refresh activities: No logged in user")
			return
		}

		await genericRefresh(endpoint: "activities/feedActivities/\(userId)") {
			[weak self] (fetchedActivities: [FullFeedActivityDTO]) in
			guard let self = self else { return }
			self.updateActivitiesForUser(fetchedActivities, userId: userId)
		}

		let duration = Date().timeIntervalSince(startTime)
		if duration > 0.5 {
			print("⏱️ [ACTIVITY-CACHE] refreshActivities took \(String(format: "%.2f", duration))s")
		}
	}

	/// Get an activity by ID from the cache
	func getActivityById(_ activityId: UUID) -> FullFeedActivityDTO? {
		return activities.values.flatMap { $0 }.first { $0.id == activityId }
	}

	/// Add or update an activity in the cache
	func addOrUpdateActivity(_ activity: FullFeedActivityDTO) {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }

		// Already on main actor, no dispatch needed
		if var userActivities = self.activities[userId] {
			if let index = userActivities.firstIndex(where: { $0.id == activity.id }) {
				userActivities[index] = activity
			} else {
				userActivities.append(activity)
			}
			self.activities[userId] = userActivities
		} else {
			self.activities[userId] = [activity]
		}

		// Ensure color is assigned for the activity
		ActivityColorService.shared.assignColorsForActivities([activity.id])

		setLastCheckedForUser(userId, cacheType: CacheKeys.events, date: Date())
		saveToDisk()
	}

	/// Remove an activity from the cache
	func removeActivity(_ activityId: UUID) {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
		if var userActivities = activities[userId] {
			userActivities.removeAll { $0.id == activityId }
			activities[userId] = userActivities
		}

		setLastCheckedForUser(userId, cacheType: CacheKeys.events, date: Date())
		saveToDisk()
	}

	/// Optimistically updates an activity in the cache
	func optimisticallyUpdateActivity(_ activity: FullFeedActivityDTO) {
		addOrUpdateActivity(activity)
	}

	/// Clean up expired activities from cache for all users
	func cleanupExpiredActivities() {
		var hasChanges = false

		for (userId, userActivities) in activities {
			let filteredActivities = userActivities.filter { activity in
				return activity.isExpired != true
			}

			if filteredActivities.count != userActivities.count {
				activities[userId] = filteredActivities
				hasChanges = true
			}
		}

		if hasChanges {
			saveToDisk()
		}
	}

	/// Clear activities for a specific user
	func clearActivitiesForUser(_ userId: UUID) {
		activities.removeValue(forKey: userId)
		saveToDisk()
	}

	// MARK: - Activity Types Methods

	/// Get activity types for the current user
	func getCurrentUserActivityTypes() -> [ActivityTypeDTO] {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("⚠️ [ACTIVITY-CACHE] getCurrentUserActivityTypes: No user ID")
			return []
		}
		let userActivityTypes = activityTypes[userId] ?? []
		print(
			"📦 [ACTIVITY-CACHE] getCurrentUserActivityTypes returned \(userActivityTypes.count) activity types for user \(userId)"
		)
		return userActivityTypes
	}

	/// Update activity types for a specific user
	func updateActivityTypesForUser(_ newActivityTypes: [ActivityTypeDTO], userId: UUID) {
		activityTypes[userId] = newActivityTypes
		setLastCheckedForUser(userId, cacheType: CacheKeys.activityTypes, date: Date())
		saveToDisk()
	}

	/// Update activity types (for all users - used by cache validation)
	func updateActivityTypes(_ newActivityTypes: [UUID: [ActivityTypeDTO]]) {
		activityTypes = newActivityTypes

		// Update timestamp for current user
		if let userId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(userId, cacheType: CacheKeys.activityTypes, date: Date())
		}

		saveToDisk()
	}

	/// Refresh activity types from the backend
	func refreshActivityTypes() async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("Cannot refresh activity types: No logged in user")
			return
		}

		await genericRefresh(endpoint: "users/\(userId)/activity-types") {
			[weak self] (fetchedActivityTypes: [ActivityTypeDTO]) in
			guard let self = self else { return }
			self.updateActivityTypesForUser(fetchedActivityTypes, userId: userId)
		}
	}

	/// Get activity types by user ID (for multi-user support)
	func getActivityTypesForUser(_ userId: UUID) -> [ActivityTypeDTO] {
		return activityTypes[userId] ?? []
	}

	/// Add or update activity types in the cache for the current user
	func addOrUpdateActivityTypes(_ newActivityTypes: [ActivityTypeDTO]) {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("⚠️ [ACTIVITY-CACHE] Cannot update activity types: No user ID")
			return
		}

		updateActivityTypesForUser(newActivityTypes, userId: userId)
	}

	/// Update a single activity type in the cache (for optimistic updates)
	func updateActivityTypeInCache(_ activityTypeDTO: ActivityTypeDTO) {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("⚠️ [ACTIVITY-CACHE] Cannot update activity type: No user ID")
			return
		}

		var userActivityTypes = activityTypes[userId] ?? []
		if let index = userActivityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
			userActivityTypes[index] = activityTypeDTO
		} else {
			userActivityTypes.append(activityTypeDTO)
		}
		activityTypes[userId] = userActivityTypes

		setLastCheckedForUser(userId, cacheType: CacheKeys.activityTypes, date: Date())
		saveToDisk()
	}

	/// Clear activity types for a specific user
	func clearActivityTypesForUser(_ userId: UUID) {
		activityTypes.removeValue(forKey: userId)
		saveToDisk()
	}

	// MARK: - Upcoming Activities Methods

	/// Get upcoming activities for a user
	func getUpcomingActivities(for userId: UUID) -> [FullFeedActivityDTO] {
		return upcomingActivities[userId] ?? []
	}

	/// Update upcoming activities for a user
	func updateUpcomingActivitiesForUser(_ newUpcomingActivities: [FullFeedActivityDTO], userId: UUID) {
		// Filter out expired activities before storing in cache
		let filteredActivities = newUpcomingActivities.filter { activity in
			return activity.isExpired != true
		}

		upcomingActivities[userId] = filteredActivities
		setLastCheckedForUser(userId, cacheType: CacheKeys.upcomingActivities, date: Date())

		// Pre-assign colors for even distribution
		let activityIds = filteredActivities.map { $0.id }
		ActivityColorService.shared.assignColorsForActivities(activityIds)

		saveToDisk()
	}

	/// Refresh upcoming activities from the backend
	func refreshUpcomingActivities() async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("Cannot refresh upcoming activities: No logged in user")
			return
		}

		await genericRefresh(endpoint: "activities/user/\(userId)/upcoming") {
			[weak self] (fetchedActivities: [FullFeedActivityDTO]) in
			guard let self = self else { return }
			self.updateUpcomingActivitiesForUser(fetchedActivities, userId: userId)
		}
	}

	/// Clear upcoming activities for a user
	func clearUpcomingActivitiesForUser(_ userId: UUID) {
		upcomingActivities.removeValue(forKey: userId)
		saveToDisk()
	}

	// MARK: - Calendar Activities Methods

	/// Generate cache key for calendar activities
	private func calendarCacheKey(userId: UUID, month: Int, year: Int) -> String {
		return "\(userId.uuidString)_\(month)_\(year)"
	}

	/// Generate cache key for all calendar activities
	private func calendarAllCacheKey(userId: UUID) -> String {
		return "\(userId.uuidString)_all"
	}

	/// Get calendar activities for a specific month
	func getCalendarActivities(for userId: UUID, month: Int, year: Int) -> [CalendarActivityDTO]? {
		let key = calendarCacheKey(userId: userId, month: month, year: year)
		return calendarActivities[key]
	}

	/// Get all calendar activities for a user
	func getAllCalendarActivities(for userId: UUID) -> [CalendarActivityDTO]? {
		let key = calendarAllCacheKey(userId: userId)
		return calendarActivities[key]
	}

	/// Update calendar activities for a specific month
	func updateCalendarActivitiesForMonth(_ activities: [CalendarActivityDTO], userId: UUID, month: Int, year: Int) {
		let key = calendarCacheKey(userId: userId, month: month, year: year)
		calendarActivities[key] = activities
		setLastCheckedForUser(userId, cacheType: "calendar_\(month)_\(year)", date: Date())

		// Pre-assign colors for calendar activities
		let activityIds = activities.compactMap { $0.activityId ?? $0.id }
		ActivityColorService.shared.assignColorsForActivities(activityIds)

		saveToDisk()
	}

	/// Update all calendar activities for a user
	func updateAllCalendarActivities(_ activities: [CalendarActivityDTO], userId: UUID) {
		let key = calendarAllCacheKey(userId: userId)
		calendarActivities[key] = activities
		setLastCheckedForUser(userId, cacheType: "calendar_all", date: Date())

		// Pre-assign colors for calendar activities
		let activityIds = activities.compactMap { $0.activityId ?? $0.id }
		ActivityColorService.shared.assignColorsForActivities(activityIds)

		saveToDisk()
	}

	/// Refresh calendar activities for a specific month from the backend
	func refreshCalendarActivities(userId: UUID, month: Int, year: Int, requestingUserId: UUID?) async {
		var parameters = [
			"month": String(month),
			"year": String(year),
		]
		if let requestingUserId = requestingUserId {
			parameters["requestingUserId"] = requestingUserId.uuidString
		}

		await genericRefresh(endpoint: "users/\(userId)/calendar", parameters: parameters) {
			[weak self] (fetchedActivities: [CalendarActivityDTO]) in
			guard let self = self else { return }
			self.updateCalendarActivitiesForMonth(fetchedActivities, userId: userId, month: month, year: year)
		}
	}

	/// Refresh all calendar activities from the backend
	func refreshAllCalendarActivities(userId: UUID, requestingUserId: UUID?) async {
		var parameters: [String: String] = [:]
		if let requestingUserId = requestingUserId {
			parameters["requestingUserId"] = requestingUserId.uuidString
		}

		await genericRefresh(
			endpoint: "users/\(userId)/calendar",
			parameters: parameters.isEmpty ? nil : parameters
		) {
			[weak self] (fetchedActivities: [CalendarActivityDTO]) in
			guard let self = self else { return }
			self.updateAllCalendarActivities(fetchedActivities, userId: userId)
		}
	}

	/// Clear calendar activities for a user
	func clearCalendarActivitiesForUser(_ userId: UUID) {
		// Remove all keys that start with this user's ID
		let keysToRemove = calendarActivities.keys.filter { $0.hasPrefix(userId.uuidString) }
		for key in keysToRemove {
			calendarActivities.removeValue(forKey: key)
		}
		saveToDisk()
	}

	// MARK: - CacheService Protocol

	func clearAllCaches() {
		activities = [:]
		activityTypes = [:]
		upcomingActivities = [:]
		calendarActivities = [:]
		lastChecked = [:]

		// Clear UserDefaults data on background task
		Task.detached(priority: .utility) {
			UserDefaults.standard.removeObject(forKey: CacheKeys.events)
			UserDefaults.standard.removeObject(forKey: CacheKeys.activityTypes)
			UserDefaults.standard.removeObject(forKey: CacheKeys.upcomingActivities)
			UserDefaults.standard.removeObject(forKey: CacheKeys.calendarActivities)
			UserDefaults.standard.removeObject(forKey: CacheKeys.lastChecked)
		}
	}

	func clearDataForUser(_ userId: UUID) {
		clearActivitiesForUser(userId)
		clearActivityTypesForUser(userId)
		clearUpcomingActivitiesForUser(userId)
		clearCalendarActivitiesForUser(userId)

		// Clear activity color preferences
		ActivityColorService.shared.clearColorPreferencesForUser(userId)

		// Clear cache timestamps for this user
		clearLastCheckedForUser(userId)

		print("💾 [ACTIVITY-CACHE] Cleared all cached data for user \(userId)")
		saveToDisk()
	}

	func validateCache(userId: UUID, timestamps: [String: Date]) async {
		// Implementation will be called from CacheCoordinator
	}

	func forceRefreshAll() async {
		print("🔄 [ACTIVITY-CACHE] Force refreshing all activity data")
		async let activitiesTask: () = refreshActivities()
		async let activityTypesTask: () = refreshActivityTypes()
		async let upcomingTask: () = refreshUpcomingActivities()

		await activitiesTask
		await activityTypesTask
		await upcomingTask
		// Note: Calendar activities are not force-refreshed here as they require specific month/year parameters
	}

	// MARK: - Persistence

	override func saveToDisk() {
		// Capture data on main actor BEFORE passing to background closure
		let capturedActivities = self.activities
		let capturedActivityTypes = self.activityTypes
		let capturedUpcomingActivities = self.upcomingActivities
		let capturedCalendarActivities = self.calendarActivities
		let capturedTimestamps = self.lastChecked

		debouncedSaveToDisk { [weak self] in
			guard let self = self else { return }

			// Encode and write on background queue using captured data
			self.saveToDefaults(capturedActivities, key: CacheKeys.events)
			self.saveToDefaults(capturedActivityTypes, key: CacheKeys.activityTypes)
			self.saveToDefaults(capturedUpcomingActivities, key: CacheKeys.upcomingActivities)
			self.saveToDefaults(capturedCalendarActivities, key: CacheKeys.calendarActivities)
			self.saveToDefaults(capturedTimestamps, key: CacheKeys.lastChecked)
		}
	}

	/// Async version of loadFromDisk that properly handles main actor isolation
	private func loadFromDiskAsync() async {
		// Load data on background queue to avoid blocking main thread
		let activities: [UUID: [FullFeedActivityDTO]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.events)
		}.value

		let activityTypes: [UUID: [ActivityTypeDTO]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.activityTypes)
		}.value

		let upcomingActivities: [UUID: [FullFeedActivityDTO]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.upcomingActivities)
		}.value

		let calendarActivities: [String: [CalendarActivityDTO]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.calendarActivities)
		}.value

		let timestamps: [UUID: [String: Date]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.lastChecked)
		}.value

		// Update @Published properties - already on MainActor
		if let activities { self.activities = activities }
		if let activityTypes { self.activityTypes = activityTypes }
		if let upcomingActivities { self.upcomingActivities = upcomingActivities }
		if let calendarActivities { self.calendarActivities = calendarActivities }
		if let timestamps { self.lastChecked = timestamps }
	}

	// MARK: - Profile Picture Preloading

	/// Preload profile pictures for activity creators and participants
	private func preloadProfilePicturesForActivities(_ activities: [UUID: [FullFeedActivityDTO]]) async {
		let profilePictureCache = ProfilePictureCache.shared

		// Use withTaskGroup to preload all profile pictures in parallel
		await withTaskGroup(of: Void.self) { group in
			for (_, activityList) in activities {
				for activity in activityList {
					// Preload creator profile picture
					if let creatorPicture = activity.creatorUser.profilePicture {
						group.addTask {
							_ = await profilePictureCache.getCachedImageWithRefresh(
								for: activity.creatorUser.id,
								from: creatorPicture,
								maxAge: 6 * 60 * 60  // 6 hours
							)
						}
					}

					// Preload participant profile pictures
					if let participants = activity.participantUsers {
						for participant in participants {
							if let participantPicture = participant.profilePicture {
								group.addTask {
									_ = await profilePictureCache.getCachedImageWithRefresh(
										for: participant.id,
										from: participantPicture,
										maxAge: 6 * 60 * 60  // 6 hours
									)
								}
							}
						}
					}

					// Preload invited user profile pictures
					if let invitedUsers = activity.invitedUsers {
						for invitedUser in invitedUsers {
							if let invitedPicture = invitedUser.profilePicture {
								group.addTask {
									_ = await profilePictureCache.getCachedImageWithRefresh(
										for: invitedUser.id,
										from: invitedPicture,
										maxAge: 6 * 60 * 60  // 6 hours
									)
								}
							}
						}
					}

					// Preload chat message senders' profile pictures
					if let chatMessages = activity.chatMessages {
						for chatMessage in chatMessages {
							if let senderPicture = chatMessage.senderUser.profilePicture {
								group.addTask {
									_ = await profilePictureCache.getCachedImageWithRefresh(
										for: chatMessage.senderUser.id,
										from: senderPicture,
										maxAge: 6 * 60 * 60  // 6 hours
									)
								}
							}
						}
					}
				}
			}
		}
	}
}
