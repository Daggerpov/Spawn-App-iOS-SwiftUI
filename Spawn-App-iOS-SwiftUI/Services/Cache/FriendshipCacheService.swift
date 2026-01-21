//
//  FriendshipCacheService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-07.
//

import Combine
import Foundation
import SwiftUI

/// Cache service for friendship-related data
@MainActor
final class FriendshipCacheService: BaseCacheService, CacheService, ObservableObject {
	static let shared = FriendshipCacheService()

	// MARK: - Cached Data
	@Published var friends: [UUID: [FullFriendUserDTO]] = [:]
	@Published var recommendedFriends: [UUID: [RecommendedFriendUserDTO]] = [:]
	@Published var friendRequests: [UUID: [FetchFriendRequestDTO]] = [:]
	@Published var sentFriendRequests: [UUID: [FetchSentFriendRequestDTO]] = [:]
	@Published var recentlySpawnedWith: [UUID: [RecentlySpawnedUserDTO]] = [:]

	// MARK: - Constants
	private enum CacheKeys {
		static let friends = "friends"
		static let recommendedFriends = "recommendedFriends"
		static let friendRequests = "friendRequests"
		static let sentFriendRequests = "sentFriendRequests"
		static let recentlySpawnedWith = "recentlySpawnedWith"
		static let lastChecked = "friendshipCache_lastChecked"
	}

	// MARK: - Initialization
	private override init() {
		super.init()

		// Load from disk in the background, then update on main actor
		Task.detached { [weak self] in
			await self?.loadFromDiskAsync()
		}
	}

	// MARK: - Friends Methods

	/// Get friends for the current user
	func getCurrentUserFriends() -> [FullFriendUserDTO] {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("⚠️ [FRIENDSHIP-CACHE] getCurrentUserFriends: No user ID")
			return []
		}
		let userFriends = friends[userId] ?? []
		// Note: Removed verbose logging here as this method is called frequently during view updates
		return userFriends
	}

	/// Update friends for a specific user
	func updateFriendsForUser(_ newFriends: [FullFriendUserDTO], userId: UUID) {

		// Debug: Check if profile pictures are present
		_ = newFriends.filter { $0.profilePicture != nil }.count

		friends[userId] = newFriends
		setLastCheckedForUser(userId, cacheType: CacheKeys.friends, date: Date())
		saveToDisk()

		// Preload profile pictures for friends
		if !newFriends.isEmpty {
			Task {
				await preloadProfilePictures(for: [userId: newFriends])
			}
		}
	}

	/// Update all friends
	func updateFriends(_ newFriends: [UUID: [FullFriendUserDTO]]) {
		friends = newFriends

		// Update timestamp for current user
		if let userId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(userId, cacheType: CacheKeys.friends, date: Date())
		}

		saveToDisk()

		// Preload profile pictures for friends
		Task {
			await preloadProfilePictures(for: newFriends)
		}
	}

	/// Refresh friends from the backend
	func refreshFriends() async {
		let startTime = Date()

		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("Cannot refresh friends: No logged in user")
			return
		}

		await genericRefresh(endpoint: "users/friends/\(userId)") { [weak self] (fetchedFriends: [FullFriendUserDTO]) in
			guard let self = self else { return }
			self.updateFriendsForUser(fetchedFriends, userId: userId)
		}

		let duration = Date().timeIntervalSince(startTime)
		if duration > 0.5 {
			print("⏱️ [FRIENDSHIP-CACHE] refreshFriends took \(String(format: "%.2f", duration))s")
		}
	}

	/// Clear friends for a specific user
	func clearFriendsForUser(_ userId: UUID) {
		friends.removeValue(forKey: userId)
		saveToDisk()
	}

	// MARK: - Recommended Friends Methods

	/// Get recommended friends for the current user
	func getCurrentUserRecommendedFriends() -> [RecommendedFriendUserDTO] {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return [] }
		return recommendedFriends[userId] ?? []
	}

	/// Update recommended friends for a specific user
	func updateRecommendedFriendsForUser(_ newRecommendedFriends: [RecommendedFriendUserDTO], userId: UUID) {
		recommendedFriends[userId] = newRecommendedFriends
		setLastCheckedForUser(userId, cacheType: CacheKeys.recommendedFriends, date: Date())
		saveToDisk()

		// Preload profile pictures for recommended friends
		Task {
			await preloadProfilePictures(for: [userId: newRecommendedFriends])
		}
	}

	/// Update all recommended friends
	func updateRecommendedFriends(_ newRecommendedFriends: [UUID: [RecommendedFriendUserDTO]]) {
		recommendedFriends = newRecommendedFriends

		// Update timestamp for current user
		if let userId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(userId, cacheType: CacheKeys.recommendedFriends, date: Date())
		}

		saveToDisk()

		// Preload profile pictures for recommended friends
		Task {
			await preloadProfilePictures(for: newRecommendedFriends)
		}
	}

	/// Refresh recommended friends from the backend
	func refreshRecommendedFriends() async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("Cannot refresh recommended friends: No logged in user")
			return
		}

		await genericRefresh(endpoint: "users/recommended-friends/\(userId)") {
			[weak self] (fetchedRecommendedFriends: [RecommendedFriendUserDTO]) in
			guard let self = self else { return }
			self.updateRecommendedFriendsForUser(fetchedRecommendedFriends, userId: userId)
		}
	}

	/// Clear recommended friends for a specific user
	func clearRecommendedFriendsForUser(_ userId: UUID) {
		recommendedFriends.removeValue(forKey: userId)
		saveToDisk()
	}

	// MARK: - Friend Requests Methods

	/// Get friend requests for the current user
	func getCurrentUserFriendRequests() -> [FetchFriendRequestDTO] {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("⚠️ [FRIENDSHIP-CACHE] getCurrentUserFriendRequests: No user ID")
			return []
		}
		let requests = friendRequests[userId] ?? []
		print(
			"📦 [FRIENDSHIP-CACHE] getCurrentUserFriendRequests returned \(requests.count) requests for user \(userId)")
		return requests
	}

	/// Update friend requests for a specific user
	func updateFriendRequestsForUser(_ newFriendRequests: [FetchFriendRequestDTO], userId: UUID) {
		// Normalize: remove zero UUIDs and unique by id
		let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
		var seen = Set<UUID>()
		let normalized = newFriendRequests.compactMap { req -> FetchFriendRequestDTO? in
			guard req.id != zeroUUID else { return nil }
			if seen.contains(req.id) { return nil }
			seen.insert(req.id)
			return req
		}

		friendRequests[userId] = normalized
		setLastCheckedForUser(userId, cacheType: CacheKeys.friendRequests, date: Date())
		saveToDisk()

		// Preload profile pictures for friend request senders
		Task {
			await preloadProfilePicturesForFriendRequests([userId: normalized])
		}
	}

	/// Update all friend requests
	func updateFriendRequests(_ newFriendRequests: [UUID: [FetchFriendRequestDTO]]) {
		// Normalize all entries
		let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
		var normalizedMap: [UUID: [FetchFriendRequestDTO]] = [:]
		for (uid, list) in newFriendRequests {
			var seen = Set<UUID>()
			let normalized = list.compactMap { req -> FetchFriendRequestDTO? in
				guard req.id != zeroUUID else { return nil }
				if seen.contains(req.id) { return nil }
				seen.insert(req.id)
				return req
			}
			normalizedMap[uid] = normalized
		}
		friendRequests = normalizedMap

		// Update timestamp for current user
		if let userId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(userId, cacheType: CacheKeys.friendRequests, date: Date())
		}

		saveToDisk()

		// Preload profile pictures for friend request senders
		Task {
			await preloadProfilePicturesForFriendRequests(normalizedMap)
		}
	}

	/// Refresh friend requests from the backend
	func refreshFriendRequests() async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("🔄 [FRIENDSHIP-CACHE] Cannot refresh friend requests: No logged in user")
			return
		}

		guard UserAuthViewModel.shared.isLoggedIn else {
			print("🔄 [FRIENDSHIP-CACHE] Cannot refresh friend requests: User is not logged in")
			return
		}

		print("🔄 [FRIENDSHIP-CACHE] Refreshing incoming friend requests for user: \(userId)")

		await genericRefresh(endpoint: "friend-requests/incoming/\(userId)") {
			[weak self] (fetchedFriendRequests: [FetchFriendRequestDTO]) in
			guard let self = self else { return }
			print("🔄 [FRIENDSHIP-CACHE] Retrieved \(fetchedFriendRequests.count) incoming friend requests from API")
			self.updateFriendRequestsForUser(fetchedFriendRequests, userId: userId)
		}
	}

	/// Clear friend requests for a specific user
	func clearFriendRequestsForUser(_ userId: UUID) {
		friendRequests.removeValue(forKey: userId)
		saveToDisk()
	}

	// MARK: - Sent Friend Requests Methods

	/// Get sent friend requests for the current user
	func getCurrentUserSentFriendRequests() -> [FetchSentFriendRequestDTO] {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("⚠️ [FRIENDSHIP-CACHE] getCurrentUserSentFriendRequests: No user ID")
			return []
		}
		let requests = sentFriendRequests[userId] ?? []
		print(
			"📦 [FRIENDSHIP-CACHE] getCurrentUserSentFriendRequests returned \(requests.count) requests for user \(userId)"
		)
		return requests
	}

	/// Update sent friend requests for a specific user
	func updateSentFriendRequestsForUser(_ newSentFriendRequests: [FetchSentFriendRequestDTO], userId: UUID) {
		print(
			"💾 [FRIENDSHIP-CACHE] Updating sent friend requests cache for user \(userId): \(newSentFriendRequests.count) requests"
		)

		// Normalize: remove zero UUIDs and unique by id
		let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
		var seen = Set<UUID>()
		let normalized = newSentFriendRequests.compactMap { req -> FetchSentFriendRequestDTO? in
			guard req.id != zeroUUID else { return nil }
			if seen.contains(req.id) { return nil }
			seen.insert(req.id)
			return req
		}

		sentFriendRequests[userId] = normalized
		setLastCheckedForUser(userId, cacheType: CacheKeys.sentFriendRequests, date: Date())
		saveToDisk()

		// Preload profile pictures for sent friend request receivers
		Task {
			await preloadProfilePicturesForSentFriendRequests([userId: normalized])
		}
	}

	/// Update all sent friend requests
	func updateSentFriendRequests(_ newSentFriendRequests: [UUID: [FetchSentFriendRequestDTO]]) {
		let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
		var normalizedMap: [UUID: [FetchSentFriendRequestDTO]] = [:]
		for (uid, list) in newSentFriendRequests {
			var seen = Set<UUID>()
			let normalized = list.compactMap { req -> FetchSentFriendRequestDTO? in
				guard req.id != zeroUUID else { return nil }
				if seen.contains(req.id) { return nil }
				seen.insert(req.id)
				return req
			}
			normalizedMap[uid] = normalized
		}
		sentFriendRequests = normalizedMap

		// Update timestamp for current user
		if let userId = UserAuthViewModel.shared.spawnUser?.id {
			setLastCheckedForUser(userId, cacheType: CacheKeys.sentFriendRequests, date: Date())
		}

		saveToDisk()

		// Preload profile pictures for sent friend request receivers
		Task {
			await preloadProfilePicturesForSentFriendRequests(normalizedMap)
		}
	}

	/// Refresh sent friend requests from the backend
	func refreshSentFriendRequests() async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("🔄 [FRIENDSHIP-CACHE] Cannot refresh sent friend requests: No logged in user")
			return
		}

		guard UserAuthViewModel.shared.isLoggedIn else {
			print("🔄 [FRIENDSHIP-CACHE] Cannot refresh sent friend requests: User is not logged in")
			return
		}

		print("🔄 [FRIENDSHIP-CACHE] Refreshing sent friend requests for user: \(userId)")

		await genericRefresh(endpoint: "friend-requests/sent/\(userId)") {
			[weak self] (fetchedSentFriendRequests: [FetchSentFriendRequestDTO]) in
			guard let self = self else { return }
			print("🔄 [FRIENDSHIP-CACHE] Retrieved \(fetchedSentFriendRequests.count) sent friend requests from API")
			self.updateSentFriendRequestsForUser(fetchedSentFriendRequests, userId: userId)
		}
	}

	/// Clear sent friend requests for a specific user
	func clearSentFriendRequestsForUser(_ userId: UUID) {
		sentFriendRequests.removeValue(forKey: userId)
		saveToDisk()
	}

	/// Force refresh both incoming and sent friend requests
	func forceRefreshAllFriendRequests() async {
		print("🔄 [FRIENDSHIP-CACHE] Force refreshing all friend request data")
		async let incomingTask: () = refreshFriendRequests()
		async let sentTask: () = refreshSentFriendRequests()

		await incomingTask
		await sentTask
	}

	// MARK: - Recently Spawned With Methods

	/// Get recently spawned with users for a user
	func getRecentlySpawnedWith(for userId: UUID) -> [RecentlySpawnedUserDTO] {
		return recentlySpawnedWith[userId] ?? []
	}

	/// Update recently spawned with users for a user
	func updateRecentlySpawnedWithForUser(_ users: [RecentlySpawnedUserDTO], userId: UUID) {
		recentlySpawnedWith[userId] = users
		setLastCheckedForUser(userId, cacheType: CacheKeys.recentlySpawnedWith, date: Date())
		saveToDisk()

		// Preload profile pictures for recently spawned with users
		Task {
			await preloadProfilePicturesForRecentlySpawnedWith([userId: users])
		}
	}

	/// Refresh recently spawned with users from the backend
	func refreshRecentlySpawnedWith() async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("Cannot refresh recently spawned with: No logged in user")
			return
		}

		await genericRefresh(endpoint: "users/\(userId)/recent-users") {
			[weak self] (users: [RecentlySpawnedUserDTO]) in
			guard let self = self else { return }
			self.updateRecentlySpawnedWithForUser(users, userId: userId)
		}
	}

	/// Clear recently spawned with users for a user
	func clearRecentlySpawnedWithForUser(_ userId: UUID) {
		recentlySpawnedWith.removeValue(forKey: userId)
		saveToDisk()
	}

	// MARK: - CacheService Protocol

	func clearAllCaches() {
		friends = [:]
		recommendedFriends = [:]
		friendRequests = [:]
		sentFriendRequests = [:]
		recentlySpawnedWith = [:]
		lastChecked = [:]

		// Clear UserDefaults data on background task
		Task.detached(priority: .utility) {
			UserDefaults.standard.removeObject(forKey: CacheKeys.friends)
			UserDefaults.standard.removeObject(forKey: CacheKeys.recommendedFriends)
			UserDefaults.standard.removeObject(forKey: CacheKeys.friendRequests)
			UserDefaults.standard.removeObject(forKey: CacheKeys.sentFriendRequests)
			UserDefaults.standard.removeObject(forKey: CacheKeys.recentlySpawnedWith)
			UserDefaults.standard.removeObject(forKey: CacheKeys.lastChecked)
		}
	}

	func clearDataForUser(_ userId: UUID) {
		clearFriendsForUser(userId)
		clearRecommendedFriendsForUser(userId)
		clearFriendRequestsForUser(userId)
		clearSentFriendRequestsForUser(userId)
		clearRecentlySpawnedWithForUser(userId)

		// Clear cache timestamps for this user
		clearLastCheckedForUser(userId)

		print("💾 [FRIENDSHIP-CACHE] Cleared all cached data for user \(userId)")
		saveToDisk()
	}

	func validateCache(userId: UUID, timestamps: [String: Date]) async {
		// Implementation will be called from CacheCoordinator
	}

	func forceRefreshAll() async {
		print("🔄 [FRIENDSHIP-CACHE] Force refreshing all friendship data")
		async let friendsTask: () = refreshFriends()
		async let recommendedTask: () = refreshRecommendedFriends()
		async let requestsTask: () = refreshFriendRequests()
		async let sentRequestsTask: () = refreshSentFriendRequests()
		async let recentlySpawnedTask: () = refreshRecentlySpawnedWith()

		await friendsTask
		await recommendedTask
		await requestsTask
		await sentRequestsTask
		await recentlySpawnedTask
	}

	/// Diagnostic method to force refresh all data with detailed logging
	func diagnosticForceRefresh() async {
		guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
			print("❌ [DIAGNOSTIC] Cannot run diagnostic: No user ID available")
			return
		}

		print("🔍 [DIAGNOSTIC] Starting diagnostic refresh for user: \(userId)")
		print("🔍 [DIAGNOSTIC] Current state before refresh:")
		print("   - Friends: \(friends[userId]?.count ?? 0)")
		print("   - Friend requests: \(friendRequests[userId]?.count ?? 0)")
		print("   - Sent friend requests: \(sentFriendRequests[userId]?.count ?? 0)")
		print("   - Recommended friends: \(recommendedFriends[userId]?.count ?? 0)")
		print("   - Recently spawned with: \(recentlySpawnedWith[userId]?.count ?? 0)")

		await forceRefreshAll()

		print("🔍 [DIAGNOSTIC] State after refresh:")
		print("   - Friends: \(friends[userId]?.count ?? 0)")
		print("   - Friend requests: \(friendRequests[userId]?.count ?? 0)")
		print("   - Sent friend requests: \(sentFriendRequests[userId]?.count ?? 0)")
		print("   - Recommended friends: \(recommendedFriends[userId]?.count ?? 0)")
		print("   - Recently spawned with: \(recentlySpawnedWith[userId]?.count ?? 0)")
	}

	// MARK: - Persistence

	override func saveToDisk() {
		// Capture data on main actor BEFORE passing to background closure
		let capturedFriends = self.friends
		let capturedRecommended = self.recommendedFriends
		let capturedRequests = self.friendRequests
		let capturedSentRequests = self.sentFriendRequests
		let capturedRecentlySpawnedWith = self.recentlySpawnedWith
		let capturedTimestamps = self.lastChecked

		debouncedSaveToDisk { [weak self] in
			guard let self = self else { return }

			// Encode and write on background queue using captured data
			self.saveToDefaults(capturedFriends, key: CacheKeys.friends)
			self.saveToDefaults(capturedRecommended, key: CacheKeys.recommendedFriends)
			self.saveToDefaults(capturedRequests, key: CacheKeys.friendRequests)
			self.saveToDefaults(capturedSentRequests, key: CacheKeys.sentFriendRequests)
			self.saveToDefaults(capturedRecentlySpawnedWith, key: CacheKeys.recentlySpawnedWith)
			self.saveToDefaults(capturedTimestamps, key: CacheKeys.lastChecked)
		}
	}

	/// Async version of loadFromDisk that properly handles main actor isolation
	private func loadFromDiskAsync() async {
		// Load data on background queue to avoid blocking main thread
		let friends: [UUID: [FullFriendUserDTO]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.friends)
		}.value

		let recommended: [UUID: [RecommendedFriendUserDTO]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.recommendedFriends)
		}.value

		let requests: [UUID: [FetchFriendRequestDTO]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.friendRequests)
		}.value

		let sentRequests: [UUID: [FetchSentFriendRequestDTO]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.sentFriendRequests)
		}.value

		let recentlySpawned: [UUID: [RecentlySpawnedUserDTO]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.recentlySpawnedWith)
		}.value

		let timestamps: [UUID: [String: Date]]? = await Task.detached { [weak self] in
			self?.loadFromDefaults(key: CacheKeys.lastChecked)
		}.value

		// Update @Published properties - already on MainActor
		if let friends { self.friends = friends }
		if let recommended { self.recommendedFriends = recommended }
		if let requests { self.friendRequests = requests }
		if let sentRequests { self.sentFriendRequests = sentRequests }
		if let recentlySpawned { self.recentlySpawnedWith = recentlySpawned }
		if let timestamps { self.lastChecked = timestamps }
	}

	// MARK: - Profile Picture Preloading

	/// Preload profile pictures for a collection of users
	private func preloadProfilePictures<T: Nameable>(for users: [UUID: [T]]) async {
		let profilePictureCache = ProfilePictureCache.shared

		// Use withTaskGroup to preload all profile pictures in parallel
		await withTaskGroup(of: Void.self) { group in
			for (_, userList) in users {
				for user in userList {
					guard let profilePictureUrl = user.profilePicture else { continue }

					// Add each download as a parallel task
					group.addTask {
						_ = await profilePictureCache.getCachedImageWithRefresh(
							for: user.id,
							from: profilePictureUrl,
							maxAge: 6 * 60 * 60  // 6 hours
						)
					}
				}
			}
		}
	}

	/// Preload profile pictures for friend request senders
	private func preloadProfilePicturesForFriendRequests(_ friendRequests: [UUID: [FetchFriendRequestDTO]]) async {
		let profilePictureCache = ProfilePictureCache.shared

		// Use withTaskGroup to preload all profile pictures in parallel
		await withTaskGroup(of: Void.self) { group in
			for (_, requests) in friendRequests {
				for request in requests {
					if let senderPicture = request.senderUser.profilePicture {
						group.addTask {
							_ = await profilePictureCache.getCachedImageWithRefresh(
								for: request.senderUser.id,
								from: senderPicture,
								maxAge: 6 * 60 * 60  // 6 hours
							)
						}
					}
				}
			}
		}
	}

	/// Preload profile pictures for sent friend request receivers
	private func preloadProfilePicturesForSentFriendRequests(_ sentFriendRequests: [UUID: [FetchSentFriendRequestDTO]])
		async
	{
		let profilePictureCache = ProfilePictureCache.shared

		// Use withTaskGroup to preload all profile pictures in parallel
		await withTaskGroup(of: Void.self) { group in
			for (_, requests) in sentFriendRequests {
				for request in requests {
					if let receiverPicture = request.receiverUser.profilePicture {
						group.addTask {
							_ = await profilePictureCache.getCachedImageWithRefresh(
								for: request.receiverUser.id,
								from: receiverPicture,
								maxAge: 6 * 60 * 60  // 6 hours
							)
						}
					}
				}
			}
		}
	}

	/// Preload profile pictures for recently spawned with users
	private func preloadProfilePicturesForRecentlySpawnedWith(_ recentlySpawnedWith: [UUID: [RecentlySpawnedUserDTO]])
		async
	{
		let profilePictureCache = ProfilePictureCache.shared

		// Use withTaskGroup to preload all profile pictures in parallel
		await withTaskGroup(of: Void.self) { group in
			for (_, users) in recentlySpawnedWith {
				for recentUser in users {
					if let profilePicture = recentUser.user.profilePicture {
						group.addTask {
							_ = await profilePictureCache.getCachedImageWithRefresh(
								for: recentUser.user.id,
								from: profilePicture,
								maxAge: 6 * 60 * 60  // 6 hours
							)
						}
					}
				}
			}
		}
	}
}
