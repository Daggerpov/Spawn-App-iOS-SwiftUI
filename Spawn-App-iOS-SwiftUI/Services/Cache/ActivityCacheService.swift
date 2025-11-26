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
class ActivityCacheService: BaseCacheService, CacheService, ObservableObject {
	static let shared = ActivityCacheService()

	// MARK: - Cached Data
	@Published var activities: [UUID: [FullFeedActivityDTO]] = [:]
	@Published var activityTypes: [UUID: [ActivityTypeDTO]] = [:]

	// MARK: - Constants
	private enum CacheKeys {
		static let events = "events"
		static let activityTypes = "activityTypes"
		static let lastChecked = "activityCache_lastChecked"
	}

	// MARK: - Initialization
	private override init() {
		super.init()

		// Load from disk in the background
		diskQueue.async { [weak self] in
			self?.loadFromDisk()
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
		print("💾 [ACTIVITY-CACHE] Updating activities cache: \(filteredActivities.count) activities for user \(userId)")

		activities[userId] = filteredActivities
		setLastCheckedForUser(userId, cacheType: CacheKeys.events, date: Date())

		// Pre-assign colors for even distribution
		let activityIds = filteredActivities.map { $0.id }
		ActivityColorService.shared.assignColorsForActivities(activityIds)

		saveToDisk()

		// Preload profile pictures for activities
		if !filteredActivities.isEmpty {
			print("🖼️ [ACTIVITY-CACHE] Starting profile picture preload for \(filteredActivities.count) activities")
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
			(fetchedActivities: [FullFeedActivityDTO]) in
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

		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }
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

		await genericRefresh(endpoint: "users/\(userId)/activity-types") { (fetchedActivityTypes: [ActivityTypeDTO]) in
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

	// MARK: - CacheService Protocol

	func clearAllCaches() {
		activities = [:]
		activityTypes = [:]
		lastChecked = [:]

		// Clear UserDefaults data on background queue
		diskQueue.async {
			UserDefaults.standard.removeObject(forKey: CacheKeys.events)
			UserDefaults.standard.removeObject(forKey: CacheKeys.activityTypes)
			UserDefaults.standard.removeObject(forKey: CacheKeys.lastChecked)
			print("✅ [ACTIVITY-CACHE] All UserDefaults cleared")
		}
	}

	func clearDataForUser(_ userId: UUID) {
		clearActivitiesForUser(userId)
		clearActivityTypesForUser(userId)

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

		await activitiesTask
		await activityTypesTask
		print("✅ [ACTIVITY-CACHE] Force refresh completed")
	}

	// MARK: - Persistence

	override func saveToDisk() {
		debouncedSaveToDisk { [weak self] in
			guard let self = self else { return }

			// Capture data on main thread
			let capturedActivities = self.activities
			let capturedActivityTypes = self.activityTypes
			let capturedTimestamps = self.lastChecked

			// Encode and write on background queue
			self.saveToDefaults(capturedActivities, key: CacheKeys.events)
			self.saveToDefaults(capturedActivityTypes, key: CacheKeys.activityTypes)
			self.saveToDefaults(capturedTimestamps, key: CacheKeys.lastChecked)
		}
	}

	private func loadFromDisk() {
		let loadedActivities: [UUID: [FullFeedActivityDTO]]? = loadFromDefaults(key: CacheKeys.events)
		let loadedActivityTypes: [UUID: [ActivityTypeDTO]]? = loadFromDefaults(key: CacheKeys.activityTypes)
		let loadedTimestamps: [UUID: [String: Date]]? = loadFromDefaults(key: CacheKeys.lastChecked)

		// Update @Published properties on main thread
		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }

			if let activities = loadedActivities { self.activities = activities }
			if let types = loadedActivityTypes { self.activityTypes = types }
			if let timestamps = loadedTimestamps { self.lastChecked = timestamps }

			print("✅ [ACTIVITY-CACHE] Loaded data from disk")
		}
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
