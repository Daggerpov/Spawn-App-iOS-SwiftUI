//
//  ProfileCacheService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-07.
//

import Combine
import Foundation
import SwiftUI

/// Cache service for profile-related data
@MainActor
final class ProfileCacheService: BaseCacheService, CacheService, ObservableObject {
	static let shared = ProfileCacheService()

	// MARK: - Cached Data
	@Published var otherProfiles: [UUID: BaseUserDTO] = [:]
	@Published var profileStats: [UUID: UserStatsDTO] = [:]
	@Published var profileInterests: [UUID: [String]] = [:]
	@Published var profileSocialMedia: [UUID: UserSocialMediaDTO] = [:]
	@Published var profileActivities: [UUID: [ProfileActivityDTO]] = [:]

	// MARK: - Constants
	private enum CacheKeys {
		static let otherProfiles = "otherProfiles"
		static let profileStats = "profileStats"
		static let profileInterests = "profileInterests"
		static let profileSocialMedia = "profileSocialMedia"
		static let profileEvents = "profileEvents"
		static let lastChecked = "profileCache_lastChecked"
	}

	// MARK: - Initialization
	private override init() {
		super.init()

		// Load from disk in the background, then update on main actor
		Task.detached { [weak self] in
			await self?.loadFromDiskAsync()
		}
	}

	// MARK: - Other Profiles Methods

	/// Update an other user's profile
	func updateOtherProfile(_ userId: UUID, _ profile: BaseUserDTO) {
		otherProfiles[userId] = profile

		// Update timestamp for current user
		if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(currentUserId, cacheType: CacheKeys.otherProfiles, date: Date())
		}

		saveToDisk()
	}

	/// Refresh other profiles from the backend
	func refreshOtherProfiles() async {
		guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else {
			print("Cannot refresh other profiles: No logged in user")
			return
		}

		guard UserAuthViewModel.shared.isLoggedIn else {
			print("Cannot refresh other profiles: User is not logged in")
			return
		}

		let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: myUserId) : APIService()

		var usersToRemove: [UUID] = []

		for userId in otherProfiles.keys {
			do {
				guard let url = URL(string: APIService.baseURL + "users/\(userId)") else { continue }
				let fetchedProfile: BaseUserDTO = try await apiService.fetchData(from: url, parameters: nil)

				otherProfiles[userId] = fetchedProfile
			} catch let error as APIError {
				// If user not found (404), mark for removal from cache
				if case .invalidStatusCode(let statusCode) = error, statusCode == 404 {
					print("User with ID \(userId) no longer exists, removing from cache")
					usersToRemove.append(userId)
				} else {
					print("Failed to refresh profile for user \(userId): \(error.localizedDescription)")
				}
			} catch {
				print("Failed to refresh profile for user \(userId): \(error.localizedDescription)")
			}
		}

		for userId in usersToRemove {
			otherProfiles.removeValue(forKey: userId)
		}

		// Update timestamp for current user
		if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(currentUserId, cacheType: CacheKeys.otherProfiles, date: Date())
		}
		saveToDisk()
	}

	// MARK: - Profile Stats Methods

	/// Update profile stats for a user
	func updateProfileStats(_ userId: UUID, _ stats: UserStatsDTO) {
		profileStats[userId] = stats

		// Update timestamp for current user
		if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(currentUserId, cacheType: CacheKeys.profileStats, date: Date())
		}

		saveToDisk()
	}

	/// Refresh profile stats from the backend
	func refreshProfileStats(_ userId: UUID) async {
		await genericSingleRefresh(endpoint: "users/\(userId)/stats") { [weak self] (stats: UserStatsDTO) in
			guard let self = self else { return }
			self.updateProfileStats(userId, stats)
		}
	}

	// MARK: - Profile Interests Methods

	/// Update profile interests for a user
	func updateProfileInterests(_ userId: UUID, _ interests: [String]) {
		profileInterests[userId] = interests

		// Update timestamp for current user
		if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(currentUserId, cacheType: CacheKeys.profileInterests, date: Date())
		}

		saveToDisk()
	}

	/// Refresh profile interests from the backend
	func refreshProfileInterests(_ userId: UUID) async {
		await genericRefresh(endpoint: "users/\(userId)/interests") { [weak self] (interests: [String]) in
			guard let self = self else { return }
			self.updateProfileInterests(userId, interests)
		}
	}

	// MARK: - Profile Social Media Methods

	/// Update profile social media for a user
	func updateProfileSocialMedia(_ userId: UUID, _ socialMedia: UserSocialMediaDTO) {
		profileSocialMedia[userId] = socialMedia

		// Update timestamp for current user
		if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(currentUserId, cacheType: CacheKeys.profileSocialMedia, date: Date())
		}

		saveToDisk()
	}

	/// Refresh profile social media from the backend
	func refreshProfileSocialMedia(_ userId: UUID) async {
		await genericSingleRefresh(endpoint: "users/\(userId)/social-media") {
			[weak self] (socialMedia: UserSocialMediaDTO) in
			guard let self = self else { return }
			self.updateProfileSocialMedia(userId, socialMedia)
		}
	}

	// MARK: - Profile Activities Methods

	/// Update profile activities for a user
	func updateProfileActivities(_ userId: UUID, _ activities: [ProfileActivityDTO]) {
		profileActivities[userId] = activities

		// Pre-assign colors for even distribution
		let activityIds = activities.map { $0.id }
		ActivityColorService.shared.assignColorsForActivities(activityIds)

		// Update timestamp for current user
		if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(currentUserId, cacheType: CacheKeys.profileEvents, date: Date())
		}

		saveToDisk()
	}

	/// Refresh profile activities from the backend
	func refreshProfileActivities(_ userId: UUID) async {
		guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else {
			print("Cannot refresh profile activities: No logged in user")
			return
		}

		let parameters = ["requestingUserId": myUserId.uuidString]
		await genericRefresh(endpoint: "activities/profile/\(userId)", parameters: parameters) {
			(activities: [ProfileActivityDTO]) in
			self.updateProfileActivities(userId, activities)
		}
	}

	// MARK: - CacheService Protocol

	func clearAllCaches() {
		otherProfiles = [:]
		profileStats = [:]
		profileInterests = [:]
		profileSocialMedia = [:]
		profileActivities = [:]
		lastChecked = [:]

		// Clear UserDefaults data on background task
		Task.detached(priority: .utility) {
			UserDefaults.standard.removeObject(forKey: CacheKeys.otherProfiles)
			UserDefaults.standard.removeObject(forKey: CacheKeys.profileStats)
			UserDefaults.standard.removeObject(forKey: CacheKeys.profileInterests)
			UserDefaults.standard.removeObject(forKey: CacheKeys.profileSocialMedia)
			UserDefaults.standard.removeObject(forKey: CacheKeys.profileEvents)
			UserDefaults.standard.removeObject(forKey: CacheKeys.lastChecked)
		}
	}

	func clearDataForUser(_ userId: UUID) {
		// Clear profile-specific data
		profileStats.removeValue(forKey: userId)
		profileInterests.removeValue(forKey: userId)
		profileSocialMedia.removeValue(forKey: userId)
		profileActivities.removeValue(forKey: userId)

		// Clear profile picture cache for this user
		Task {
			await ProfilePictureCache.shared.removeCachedImage(for: userId)
		}

		// Clear cache timestamps for this user
		clearLastCheckedForUser(userId)

		print("💾 [PROFILE-CACHE] Cleared all cached data for user \(userId)")
		saveToDisk()
	}

	func validateCache(userId: UUID, timestamps: [String: Date]) async {
		// Implementation will be called from CacheCoordinator
	}

	func forceRefreshAll() async {
		print("🔄 [PROFILE-CACHE] Force refreshing all profile data")
		await refreshOtherProfiles()
	}

	// MARK: - Persistence

	override func saveToDisk() {
		// Capture data on main actor BEFORE passing to background closure
		let capturedProfiles = self.otherProfiles
		let capturedStats = self.profileStats
		let capturedInterests = self.profileInterests
		let capturedSocialMedia = self.profileSocialMedia
		let capturedActivities = self.profileActivities
		let capturedTimestamps = self.lastChecked

		debouncedSaveToDisk { [weak self] in
			guard let self = self else { return }

			// Encode and write on background queue using captured data
			self.saveToDefaults(capturedProfiles, key: CacheKeys.otherProfiles)
			self.saveToDefaults(capturedStats, key: CacheKeys.profileStats)
			self.saveToDefaults(capturedInterests, key: CacheKeys.profileInterests)
			self.saveToDefaults(capturedSocialMedia, key: CacheKeys.profileSocialMedia)
			self.saveToDefaults(capturedActivities, key: CacheKeys.profileEvents)
			self.saveToDefaults(capturedTimestamps, key: CacheKeys.lastChecked)
		}
	}

	/// Async version of loadFromDisk that properly handles main actor isolation
	private func loadFromDiskAsync() async {
		// Load data on background queue to avoid blocking main thread
		let profiles: [UUID: BaseUserDTO]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.otherProfiles)
		}.value

		let stats: [UUID: UserStatsDTO]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.profileStats)
		}.value

		let interests: [UUID: [String]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.profileInterests)
		}.value

		let socialMedia: [UUID: UserSocialMediaDTO]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.profileSocialMedia)
		}.value

		let activities: [UUID: [ProfileActivityDTO]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.profileEvents)
		}.value

		let timestamps: [UUID: [String: Date]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.lastChecked)
		}.value

		// Update @Published properties - already on MainActor
		if let profiles { self.otherProfiles = profiles }
		if let stats { self.profileStats = stats }
		if let interests { self.profileInterests = interests }
		if let socialMedia { self.profileSocialMedia = socialMedia }
		if let activities { self.profileActivities = activities }
		if let timestamps { self.lastChecked = timestamps }
	}
}
