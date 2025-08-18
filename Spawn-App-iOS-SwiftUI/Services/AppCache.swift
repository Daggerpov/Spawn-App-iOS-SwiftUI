//
//  AppCache.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-04-20.
//

import Foundation
import SwiftUI
import Combine

/// A singleton cache manager that stores app data locally and checks for invalidation on app launch
class AppCache: ObservableObject {
    static let shared = AppCache()
    
    // MARK: - Cached Data
    @Published var friends: [UUID: [FullFriendUserDTO]] = [:]  // Changed to be user-specific
    @Published var activities: [UUID: [FullFeedActivityDTO]] = [:]  // Changed to be user-specific
    @Published var activityTypes: [ActivityTypeDTO] = []
    @Published var recommendedFriends: [UUID: [RecommendedFriendUserDTO]] = [:]  // Changed to be user-specific
    @Published var friendRequests: [UUID: [FetchFriendRequestDTO]] = [:]  // Already user-specific
    @Published var sentFriendRequests: [UUID: [FetchSentFriendRequestDTO]] = [:]  // User-specific sent friend requests
    @Published var otherProfiles: [UUID: BaseUserDTO] = [:]
    
    // Profile caches
    @Published var profileStats: [UUID: UserStatsDTO] = [:]
    @Published var profileInterests: [UUID: [String]] = [:]
    @Published var profileSocialMedia: [UUID: UserSocialMediaDTO] = [:]
    @Published var profileActivities: [UUID: [ProfileActivityDTO]] = [:]
    
    // MARK: - Cache Metadata
    private var lastChecked: [UUID: [String: Date]] = [:] // User-specific cache timestamps
    private var isInitialized = false
    
    // MARK: - Constants
    private enum CacheKeys {
        static let lastChecked = "lastChecked"
        static let friends = "friends"
        static let events = "events"  // Changed from "activities" to match backend
        static let activityTypes = "activityTypes"
        static let recommendedFriends = "recommendedFriends"
        static let friendRequests = "friendRequests"
        static let sentFriendRequests = "sentFriendRequests"
        static let otherProfiles = "otherProfiles"
        static let profileStats = "profileStats"
        static let profileInterests = "profileInterests"
        static let profileSocialMedia = "profileSocialMedia"
        static let profileEvents = "profileEvents"  // Changed from "profileActivities" to match backend
    }
    
    private init() {
        loadFromDisk()
        
        // Set up a timer to periodically save to disk
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.saveToDisk()
        }
    }
    
    // MARK: - Cache Timestamp Helpers
    
    /// Get cache timestamps for a specific user
    private func getLastCheckedForUser(_ userId: UUID) -> [String: Date] {
        return lastChecked[userId] ?? [:]
    }
    
    /// Set cache timestamp for a specific user and cache type
    private func setLastCheckedForUser(_ userId: UUID, cacheType: String, date: Date) {
        if lastChecked[userId] == nil {
            lastChecked[userId] = [:]
        }
        lastChecked[userId]![cacheType] = date
    }
    
    /// Clear cache timestamps for a specific user
    private func clearLastCheckedForUser(_ userId: UUID) {
        lastChecked.removeValue(forKey: userId)
    }
    
    // MARK: - Public Methods
    
    /// Initialize the cache and load from disk
    func initialize() {
        if !isInitialized {
            loadFromDisk()
            isInitialized = true
        }
    }
    
    /// Clear all cached data and reset the cache state
    func clearAllCaches() {
        // Clear all cached data
        friends = [:]
        activities = [:]
        activityTypes = []
        recommendedFriends = [:]
        friendRequests = [:] // Clear user-specific friend requests
        sentFriendRequests = [:] // Clear user-specific sent friend requests
        otherProfiles = [:]
        
        // Clear profile caches
        profileStats = [:]
        profileInterests = [:]
        profileSocialMedia = [:]
        profileActivities = [:]
        
        // Clear metadata
        lastChecked = [:]
        
        // Clear UserDefaults data
        UserDefaults.standard.removeObject(forKey: CacheKeys.lastChecked)
        UserDefaults.standard.removeObject(forKey: CacheKeys.friends)
        UserDefaults.standard.removeObject(forKey: CacheKeys.events)
        UserDefaults.standard.removeObject(forKey: CacheKeys.activityTypes)
        UserDefaults.standard.removeObject(forKey: CacheKeys.recommendedFriends)
        UserDefaults.standard.removeObject(forKey: CacheKeys.friendRequests)
        UserDefaults.standard.removeObject(forKey: CacheKeys.sentFriendRequests)
        UserDefaults.standard.removeObject(forKey: CacheKeys.otherProfiles)
        UserDefaults.standard.removeObject(forKey: CacheKeys.profileStats)
        UserDefaults.standard.removeObject(forKey: CacheKeys.profileInterests)
        UserDefaults.standard.removeObject(forKey: CacheKeys.profileSocialMedia)
        UserDefaults.standard.removeObject(forKey: CacheKeys.profileEvents)
        
        // Clear profile picture cache
        ProfilePictureCache.shared.clearAllCache()
        
        print("All caches cleared successfully")
    }
    
    /// Validate cache with backend and refresh stale items
    func validateCache() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ [CACHE] Cannot validate cache: No logged in user")
            print("🔍 [CACHE] UserAuthViewModel.shared.spawnUser is nil")
            print("🔍 [CACHE] UserAuthViewModel.shared.isLoggedIn: \(UserAuthViewModel.shared.isLoggedIn)")
            return
        }
        
        print("✅ [CACHE] Starting cache validation for user: \(userId)")
        
        // Double-check authentication state before proceeding
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("❌ [CACHE] Cannot validate cache: User is not logged in")
            print("🔍 [CACHE] User ID exists but isLoggedIn is false")
            return
        }
        
        // Clear calendar caches due to data format changes (CalendarActivityDTO date field changed from Date to String)
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            try await apiService.clearCalendarCaches()
        } catch {
            print("⚠️ Failed to clear calendar caches on startup: \(error.localizedDescription)")
            // Don't block cache validation if this fails
        }
        
        // Get user-specific cache timestamps
        let userLastChecked = getLastCheckedForUser(userId)
        
        print("🔍 [CACHE] User cache timestamps: \(userLastChecked)")
        print("🔍 [CACHE] Current cached friends count: \(friends[userId]?.count ?? 0)")
        print("🔍 [CACHE] Current cached friend requests count: \(friendRequests[userId]?.count ?? 0)")
        print("🔍 [CACHE] Current cached sent friend requests count: \(sentFriendRequests[userId]?.count ?? 0)")
        
        // If we have no cached items to validate for this user, request fresh data for all cache types
        if userLastChecked.isEmpty {
            print("🔄 [CACHE] No cached items to validate, requesting fresh data for all cache types")
            // Request fresh data for all standard cache types
            let _ = await MainActor.run {
                Task {
					async let friendsTask: () = refreshFriends()
					async let activitiesTask: () = refreshActivities()
                    async let activityTypesTask: () = refreshActivityTypes()
                    async let recommendedFriendsTask: () = refreshRecommendedFriends()
                    async let friendRequestsTask: () = refreshFriendRequests()
                    async let sentFriendRequestsTask: () = refreshSentFriendRequests()

                    // Wait for all tasks to complete
                    await friendsTask
                    await activitiesTask
                    await activityTypesTask
                    await recommendedFriendsTask
                    await friendRequestsTask
                    await sentFriendRequestsTask
                    
                    print("✅ [CACHE] Completed initial cache refresh for all cache types")
                }
            }
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            let result = try await apiService.validateCache(userLastChecked)
            
            await MainActor.run {
                // Update each collection based on invalidation results
                if let friendsResponse = result[CacheKeys.friends], friendsResponse.invalidate {
                    if let updatedItems = friendsResponse.updatedItems,
                       let updatedFriends = try? JSONDecoder().decode([UUID: [FullFriendUserDTO]].self, from: updatedItems) {
                        // Backend provided the updated data
                        updateFriends(updatedFriends)
                    } else {
                        // Need to fetch new data
                        Task {
                            await refreshFriends()
                        }
                    }
                }
                

                
                if let activitiesResponse = result[CacheKeys.events], activitiesResponse.invalidate {
                    if let updatedItems = activitiesResponse.updatedItems,
                       let updatedActivities = try? JSONDecoder().decode([UUID: [FullFeedActivityDTO]].self, from: updatedItems) {
                        // Backend provided the updated data
                        updateActivities(updatedActivities)
                    } else {
                        // Need to fetch new data
                        Task {
                            await refreshActivities()
                        }
                    }
                }
                
                // Activity Types Cache
                if let activityTypesResponse = result[CacheKeys.activityTypes], activityTypesResponse.invalidate {
                    if let updatedItems = activityTypesResponse.updatedItems,
                       let updatedActivityTypes = try? JSONDecoder().decode([ActivityTypeDTO].self, from: updatedItems) {
                        // Backend provided the updated data
                        updateActivityTypes(updatedActivityTypes)
                    } else {
                        // Need to fetch new data
                        Task {
                            await refreshActivityTypes()
                        }
                    }
                }
                
                // Other Profiles Cache
                if let otherProfilesResponse = result[CacheKeys.otherProfiles], otherProfilesResponse.invalidate {
                    Task {
                        await refreshOtherProfiles()
                    }
                }
                
                // Recommended Friends Cache
                if let recommendedFriendsResponse = result[CacheKeys.recommendedFriends], recommendedFriendsResponse.invalidate {
                    if let updatedItems = recommendedFriendsResponse.updatedItems,
                       let updatedRecommendedFriends = try? JSONDecoder().decode([UUID: [RecommendedFriendUserDTO]].self, from: updatedItems) {
                        updateRecommendedFriends(updatedRecommendedFriends)
                    } else {
                        Task {
                            await refreshRecommendedFriends()
                        }
                    }
                }
                
                // Friend Requests Cache
                if let friendRequestsResponse = result[CacheKeys.friendRequests], friendRequestsResponse.invalidate {
                    if let updatedItems = friendRequestsResponse.updatedItems,
                       let updatedFriendRequests = try? JSONDecoder().decode([UUID: [FetchFriendRequestDTO]].self, from: updatedItems) {
                        updateFriendRequests(updatedFriendRequests)
                    } else {
                        Task {
                            await refreshFriendRequests()
                        }
                    }
                }
                
                // Sent Friend Requests Cache
                if let sentFriendRequestsResponse = result[CacheKeys.sentFriendRequests], sentFriendRequestsResponse.invalidate {
                    if let updatedItems = sentFriendRequestsResponse.updatedItems,
                       let updatedSentFriendRequests = try? JSONDecoder().decode([UUID: [FetchSentFriendRequestDTO]].self, from: updatedItems) {
                        updateSentFriendRequests(updatedSentFriendRequests)
                    } else {
                        Task {
                            await refreshSentFriendRequests()
                        }
                    }
                }
            }
            
        } catch {
            print("Failed to validate cache: \(error.localizedDescription)")
            // If validation fails, we'll continue using cached data
        }
        
        // After cache validation, refresh profile pictures for all cached users
        Task {
            await refreshAllProfilePictures()
        }
    }
    
    // MARK: - Friends Methods
    
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
    
    func refreshFriends() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh friends: No logged in user")
            return 
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot refresh friends: User is not logged in")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/friends/\(userId)") else { return }
            
            let fetchedFriends: [FullFriendUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateFriendsForUser(fetchedFriends, userId: userId)
            }
        } catch {
            print("Failed to refresh friends: \(error.localizedDescription)")
        }
    }
    

    
    // MARK: - Activities Methods
    
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
    
    func refreshActivities() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh activities: No logged in user")
            return 
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot refresh activities: User is not logged in")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "activities/feedActivities/\(userId)") else { return }
            
            let fetchedActivities: [FullFeedActivityDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateActivitiesForUser(fetchedActivities, userId: userId)
            }
        } catch {
            print("Failed to refresh activities: \(error.localizedDescription)")
        }
    }
    
    // Get an activity by ID from the cache
    func getActivityById(_ activityId: UUID) -> FullFeedActivityDTO? {
        return activities.values.flatMap { $0 }.first { $0.id == activityId }
    }
    
    // Add or update an activity in the cache
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
        
        // Update timestamp for current user
        if let userId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(userId, cacheType: CacheKeys.events, date: Date())
        }
        saveToDisk()
    }
    
    // Remove an activity from the cache
    func removeActivity(_ activityId: UUID) {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        if var userActivities = activities[userId] {
            userActivities.removeAll { $0.id == activityId }
            activities[userId] = userActivities
        }
        
        // Update timestamp for current user
        if let userId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(userId, cacheType: CacheKeys.events, date: Date())
        }
        saveToDisk()
    }
    
    /// Optimistically updates an activity in the cache
    func optimisticallyUpdateActivity(_ activity: FullFeedActivityDTO) {
        addOrUpdateActivity(activity)
    }
    
    // MARK: - Activity Types Methods
    
    func updateActivityTypes(_ newActivityTypes: [ActivityTypeDTO]) {
        activityTypes = newActivityTypes
        
        // Update timestamp for current user
        if let userId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(userId, cacheType: CacheKeys.activityTypes, date: Date())
        }
        
        saveToDisk()
    }
    
    func refreshActivityTypes() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh activity types: No logged in user")
            return 
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot refresh activity types: User is not logged in")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/\(userId)/activity-types") else { return }
            
            let fetchedActivityTypes: [ActivityTypeDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateActivityTypes(fetchedActivityTypes)
            }
        } catch {
            print("Failed to refresh activity types: \(error.localizedDescription)")
        }
    }
    
    // Get activity types by user ID (for multi-user support)
    func getActivityTypesForUser(_ userId: UUID) -> [ActivityTypeDTO] {
        // For now, return the cached activity types (single user)
        return activityTypes
    }
    
    // Add or update activity types in the cache
    func addOrUpdateActivityTypes(_ newActivityTypes: [ActivityTypeDTO]) {
        activityTypes = newActivityTypes
        
        // Update timestamp for current user
        if let userId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(userId, cacheType: CacheKeys.activityTypes, date: Date())
        }
        
        saveToDisk()
    }
    
    // Update a single activity type in the cache (for optimistic updates)
    func updateActivityTypeInCache(_ activityTypeDTO: ActivityTypeDTO) {
        if let index = activityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
            activityTypes[index] = activityTypeDTO
        } else {
            activityTypes.append(activityTypeDTO)
        }
        
        // Update timestamp for current user
        if let userId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(userId, cacheType: CacheKeys.activityTypes, date: Date())
        }
        
        saveToDisk()
    }
    
    // MARK: - Other Profiles Methods
    
    func updateOtherProfile(_ userId: UUID, _ profile: BaseUserDTO) {
        otherProfiles[userId] = profile
        
        // Update timestamp for current user
        if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(currentUserId, cacheType: CacheKeys.otherProfiles, date: Date())
        }
        
        saveToDisk()
    }
    
    func refreshOtherProfiles() async {
        // Since this is a collection of individual profiles,
        // we'll refresh all the profiles we currently have cached
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
                
                await MainActor.run {
                    otherProfiles[userId] = fetchedProfile
                }
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

		for userId in usersToRemove{
			otherProfiles.removeValue(forKey: userId)
		}

        await MainActor.run {
            // Update timestamp for current user
            if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
                setLastCheckedForUser(currentUserId, cacheType: CacheKeys.otherProfiles, date: Date())
            }
            saveToDisk()
        }
    }
    
    // MARK: - Recommended Friends Methods
    
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
    
    func refreshRecommendedFriends() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh recommended friends: No logged in user")
            return 
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot refresh recommended friends: User is not logged in")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/recommended-friends/\(userId)") else { return }
            
            let fetchedRecommendedFriends: [RecommendedFriendUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateRecommendedFriendsForUser(fetchedRecommendedFriends, userId: userId)
            }
        } catch {
            print("Failed to refresh recommended friends: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Friend Requests Methods

    /// Get friend requests for the current user
    func getCurrentUserFriendRequests() -> [FetchFriendRequestDTO] {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ [CACHE] getCurrentUserFriendRequests: No user ID available")
            print("🔍 [CACHE] UserAuthViewModel.shared.spawnUser is nil")
            return []
        }
        // Always return the latest in-memory value; this map is only mutated by API refresh/update methods
        return friendRequests[userId] ?? []
    }

    /// Update friend requests for a specific user
    func updateFriendRequestsForUser(_ newFriendRequests: [FetchFriendRequestDTO], userId: UUID) {
        print("💾 [CACHE] Updating incoming friend requests cache for user \(userId): \(newFriendRequests.count) requests")
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

    func refreshFriendRequests() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("🔄 [CACHE] Cannot refresh friend requests: No logged in user")
            return 
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("🔄 [CACHE] Cannot refresh friend requests: User is not logged in")
            return
        }
        
        print("🔄 [CACHE] Refreshing incoming friend requests for user: \(userId)")
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "friend-requests/incoming/\(userId)") else { return }
            
            let fetchedFriendRequests: [FetchFriendRequestDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            print("🔄 [CACHE] Retrieved \(fetchedFriendRequests.count) incoming friend requests from API")
            
            await MainActor.run {
                updateFriendRequestsForUser(fetchedFriendRequests, userId: userId)
            }
        } catch {
            print("❌ [CACHE] Failed to refresh friend requests: \(error.localizedDescription)")
        }
    }

    /// Clear friend requests for a specific user (useful when user logs out or switches)
    func clearFriendRequestsForUser(_ userId: UUID) {
        friendRequests.removeValue(forKey: userId)
        saveToDisk()
    }
    
    // MARK: - Sent Friend Requests Methods

    /// Get sent friend requests for the current user
    func getCurrentUserSentFriendRequests() -> [FetchFriendRequestDTO] {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return [] }
        // Always return the latest in-memory value; this map is only mutated by API refresh/update methods
        return sentFriendRequests[userId] ?? []
    }

    /// Update sent friend requests for a specific user
    func updateSentFriendRequestsForUser(_ newSentFriendRequests: [FetchSentFriendRequestDTO], userId: UUID) {
        print("💾 [CACHE] Updating sent friend requests cache for user \(userId): \(newSentFriendRequests.count) requests")
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
            await preloadProfilePicturesForFriendRequests([userId: normalized])
        }
    }

    func updateSentFriendRequests(_ newSentFriendRequests: [UUID: [FetchFriendRequestDTO]]) {
        let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        var normalizedMap: [UUID: [FetchFriendRequestDTO]] = [:]
        for (uid, list) in newSentFriendRequests {
            var seen = Set<UUID>()
            let normalized = list.compactMap { req -> FetchFriendRequestDTO? in
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
            await preloadProfilePicturesForFriendRequests(normalizedMap)
        }
    }

    func refreshSentFriendRequests() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("🔄 [CACHE] Cannot refresh sent friend requests: No logged in user")
            return 
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("🔄 [CACHE] Cannot refresh sent friend requests: User is not logged in")
            return
        }
        
        print("🔄 [CACHE] Refreshing sent friend requests for user: \(userId)")
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "friend-requests/sent/\(userId)") else { return }
            
            let fetchedSentFriendRequests: [FetchFriendRequestDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            print("🔄 [CACHE] Retrieved \(fetchedSentFriendRequests.count) sent friend requests from API")
            
            await MainActor.run {
                updateSentFriendRequestsForUser(fetchedSentFriendRequests, userId: userId)
            }
        } catch {
            print("❌ [CACHE] Failed to refresh sent friend requests: \(error.localizedDescription)")
        }
    }

    /// Clear sent friend requests for a specific user (useful when user logs out or switches)
    func clearSentFriendRequestsForUser(_ userId: UUID) {
        sentFriendRequests.removeValue(forKey: userId)
        saveToDisk()
    }
    
    /// Force refresh both incoming and sent friend requests (bypasses cache)
    func forceRefreshAllFriendRequests() async {
        print("🔄 [CACHE] Force refreshing all friend request data")
		async let incomingTask: () = refreshFriendRequests()
		async let sentTask: () = refreshSentFriendRequests()
        
        await incomingTask
        await sentTask
        print("✅ [CACHE] Force refresh of friend requests completed")
    }
    
    /// Diagnostic method to force refresh all data and provide detailed logging
    func diagnosticForceRefresh() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ [DIAGNOSTIC] Cannot run diagnostic: No user ID available")
            print("🔍 [DIAGNOSTIC] UserAuthViewModel.shared.spawnUser: \(UserAuthViewModel.shared.spawnUser?.username ?? "nil")")
            print("🔍 [DIAGNOSTIC] UserAuthViewModel.shared.isLoggedIn: \(UserAuthViewModel.shared.isLoggedIn)")
            return
        }
        
        print("🔍 [DIAGNOSTIC] Starting diagnostic refresh for user: \(userId)")
        print("🔍 [DIAGNOSTIC] Current state before refresh:")
        print("   - Friends: \(friends[userId]?.count ?? 0)")
        print("   - Friend requests: \(friendRequests[userId]?.count ?? 0)")
        print("   - Sent friend requests: \(sentFriendRequests[userId]?.count ?? 0)")
        print("   - Recommended friends: \(recommendedFriends[userId]?.count ?? 0)")
        
        // Force refresh all data
        async let friendsTask: () = refreshFriends()
        async let friendRequestsTask: () = refreshFriendRequests()
        async let sentFriendRequestsTask: () = refreshSentFriendRequests()
        async let recommendedFriendsTask: () = refreshRecommendedFriends()
        
        await friendsTask
        await friendRequestsTask
        await sentFriendRequestsTask
        await recommendedFriendsTask
        
        print("🔍 [DIAGNOSTIC] State after refresh:")
        print("   - Friends: \(friends[userId]?.count ?? 0)")
        print("   - Friend requests: \(friendRequests[userId]?.count ?? 0)")
        print("   - Sent friend requests: \(sentFriendRequests[userId]?.count ?? 0)")
        print("   - Recommended friends: \(recommendedFriends[userId]?.count ?? 0)")
        print("✅ [DIAGNOSTIC] Diagnostic refresh completed")
    }
    
    /// Force refresh profile pictures for all cached users
    func refreshAllProfilePictures() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ [CACHE] Cannot refresh profile pictures: No user ID available")
            return
        }
        
        print("🔄 [CACHE] Starting profile picture refresh for all cached users")
        let profilePictureCache = ProfilePictureCache.shared
        
        var usersToRefresh: [(userId: UUID, profilePictureUrl: String?)] = []
        
        // Collect all users from different caches
        if let userFriends = friends[userId] {
            for friend in userFriends {
                usersToRefresh.append((userId: friend.id, profilePictureUrl: friend.profilePicture))
            }
        }
        
        if let userRecommendedFriends = recommendedFriends[userId] {
            for friend in userRecommendedFriends {
                usersToRefresh.append((userId: friend.id, profilePictureUrl: friend.profilePicture))
            }
        }
        
        if let userFriendRequests = friendRequests[userId] {
            for request in userFriendRequests {
                usersToRefresh.append((userId: request.senderUser.id, profilePictureUrl: request.senderUser.profilePicture))
            }
        }
        
        if let userSentFriendRequests = sentFriendRequests[userId] {
            for request in userSentFriendRequests {
                usersToRefresh.append((userId: request.receiverUser.id, profilePictureUrl: request.receiverUser.profilePicture))
            }
        }
        
        // Add other profiles
        for (_, profile) in otherProfiles {
            usersToRefresh.append((userId: profile.id, profilePictureUrl: profile.profilePicture))
        }
        
        // Add current user
        if let currentUser = UserAuthViewModel.shared.spawnUser {
            usersToRefresh.append((userId: currentUser.id, profilePictureUrl: currentUser.profilePicture))
        }
        
        // Remove duplicates
        var seen = Set<UUID>()
        let uniqueUsers = usersToRefresh.compactMap { user in
            guard !seen.contains(user.userId) else { return nil }
            seen.insert(user.userId)
            return user
        }
        
        print("🔄 [CACHE] Found \(uniqueUsers.count) unique users to refresh profile pictures for")
        
        // Refresh stale profile pictures
        await profilePictureCache.refreshStaleProfilePictures(for: uniqueUsers)
        
        print("✅ [CACHE] Completed profile picture refresh for all cached users")
    }
    
    /// Force refresh profile pictures for all cached users (public method for testing)
    func forceRefreshAllProfilePictures() async {
        print("🔄 [CACHE] Force refreshing ALL profile pictures (bypassing staleness check)")
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ [CACHE] Cannot refresh profile pictures: No user ID available")
            return
        }
        
        let profilePictureCache = ProfilePictureCache.shared
        var usersToRefresh: [(userId: UUID, profilePictureUrl: String?)] = []
        
        // Collect all users from different caches
        if let userFriends = friends[userId] {
            for friend in userFriends {
                usersToRefresh.append((userId: friend.id, profilePictureUrl: friend.profilePicture))
            }
        }
        
        if let userRecommendedFriends = recommendedFriends[userId] {
            for friend in userRecommendedFriends {
                usersToRefresh.append((userId: friend.id, profilePictureUrl: friend.profilePicture))
            }
        }
        
        if let userFriendRequests = friendRequests[userId] {
            for request in userFriendRequests {
                usersToRefresh.append((userId: request.senderUser.id, profilePictureUrl: request.senderUser.profilePicture))
            }
        }
        
        if let userSentFriendRequests = sentFriendRequests[userId] {
            for request in userSentFriendRequests {
                usersToRefresh.append((userId: request.receiverUser.id, profilePictureUrl: request.receiverUser.profilePicture))
            }
        }
        
        // Add other profiles
        for (_, profile) in otherProfiles {
            usersToRefresh.append((userId: profile.id, profilePictureUrl: profile.profilePicture))
        }
        
        // Add current user
        if let currentUser = UserAuthViewModel.shared.spawnUser {
            usersToRefresh.append((userId: currentUser.id, profilePictureUrl: currentUser.profilePicture))
        }
        
        // Remove duplicates
        var seen = Set<UUID>()
        let uniqueUsers = usersToRefresh.compactMap { user in
            guard !seen.contains(user.userId) else { return nil }
            seen.insert(user.userId)
            return user
        }
        
        print("🔄 [CACHE] Force refreshing \(uniqueUsers.count) unique users' profile pictures")
        
        // Force refresh all profile pictures
        for user in uniqueUsers {
            guard let profilePictureUrl = user.profilePictureUrl else { continue }
            _ = await profilePictureCache.refreshProfilePicture(for: user.userId, from: profilePictureUrl)
        }
        
        print("✅ [CACHE] Completed force refresh of all profile pictures")
    }
    
    // MARK: - User-Specific Data Helper Methods
    
    /// Get friends for the current user
    func getCurrentUserFriends() -> [FullFriendUserDTO] {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("❌ [CACHE] getCurrentUserFriends: No user ID available")
            print("🔍 [CACHE] UserAuthViewModel.shared.spawnUser is nil")
            return [] 
        }
        let userFriends = friends[userId] ?? []
        print("🔍 [CACHE] getCurrentUserFriends for user \(userId): returning \(userFriends.count) friends")
        return userFriends
    }
    
    /// Update friends for a specific user
    func updateFriendsForUser(_ newFriends: [FullFriendUserDTO], userId: UUID) {
        friends[userId] = newFriends
        setLastCheckedForUser(userId, cacheType: CacheKeys.friends, date: Date())
        saveToDisk()
        
        // Preload profile pictures for friends
        Task {
            await preloadProfilePictures(for: [userId: newFriends])
        }
    }
    
    /// Clear friends for a specific user
    func clearFriendsForUser(_ userId: UUID) {
        friends.removeValue(forKey: userId)
        saveToDisk()
    }
    
    /// Get activities for the current user
    func getCurrentUserActivities() -> [FullFeedActivityDTO] {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return [] }
        return activities[userId] ?? []
    }
    
    /// Update activities for a specific user
    func updateActivitiesForUser(_ newActivities: [FullFeedActivityDTO], userId: UUID) {
        activities[userId] = newActivities
        setLastCheckedForUser(userId, cacheType: CacheKeys.events, date: Date())
        
        // Pre-assign colors for even distribution
        let activityIds = newActivities.map { $0.id }
        ActivityColorService.shared.assignColorsForActivities(activityIds)
        
        saveToDisk()
        
        // Preload profile pictures for activities
        Task {
            await preloadProfilePicturesForActivities([userId: newActivities])
        }
    }
    
    /// Clear activities for a specific user
    func clearActivitiesForUser(_ userId: UUID) {
        activities.removeValue(forKey: userId)
        saveToDisk()
    }
    
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
    
    /// Clear recommended friends for a specific user
    func clearRecommendedFriendsForUser(_ userId: UUID) {
        recommendedFriends.removeValue(forKey: userId)
        saveToDisk()
    }
    
    /// Clear all data for a specific user (useful when user logs out or switches)
    func clearAllDataForUser(_ userId: UUID) {
        clearFriendsForUser(userId)
        clearActivitiesForUser(userId)
        clearRecommendedFriendsForUser(userId)
        clearFriendRequestsForUser(userId)
        
        // Clear profile-specific data
        profileStats.removeValue(forKey: userId)
        profileInterests.removeValue(forKey: userId)
        profileSocialMedia.removeValue(forKey: userId)
        profileActivities.removeValue(forKey: userId)
        
        // Clear profile picture cache for this user
        ProfilePictureCache.shared.removeCachedImage(for: userId)
        
        // Clear other profiles cache to prevent data leakage between users
        otherProfiles.removeAll()
        
        // Clear notification preferences
        NotificationService.shared.clearPreferencesForUser(userId)
        
        // Clear activity color preferences
        ActivityColorService.shared.clearColorPreferencesForUser(userId)
        
        // Clear cache timestamps for this user
        clearLastCheckedForUser(userId)
        
        print("💾 [CACHE] Cleared all cached data and preferences for user \(userId)")
        saveToDisk()
    }
    
    // MARK: - Profile Methods
    
    func updateProfileStats(_ userId: UUID, _ stats: UserStatsDTO) {
        profileStats[userId] = stats
        
        // Update timestamp for current user
        if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(currentUserId, cacheType: CacheKeys.profileStats, date: Date())
        }
        
        saveToDisk()
    }
    
    func updateProfileInterests(_ userId: UUID, _ interests: [String]) {
        profileInterests[userId] = interests
        
        // Update timestamp for current user
        if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(currentUserId, cacheType: CacheKeys.profileInterests, date: Date())
        }
        
        saveToDisk()
    }
    
    func updateProfileSocialMedia(_ userId: UUID, _ socialMedia: UserSocialMediaDTO) {
        profileSocialMedia[userId] = socialMedia
        
        // Update timestamp for current user
        if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(currentUserId, cacheType: CacheKeys.profileSocialMedia, date: Date())
        }
        
        saveToDisk()
    }
    

    
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
    
    // MARK: - Profile Picture Caching
    
    /// Preload profile pictures for a collection of users
    private func preloadProfilePictures<T: Nameable>(for users: [UUID: [T]]) async {
        let profilePictureCache = ProfilePictureCache.shared
        
        for (_, userList) in users {
            for user in userList {
                guard let profilePictureUrl = user.profilePicture else { continue }
                
                // Use the new refresh mechanism that checks for staleness
                _ = await profilePictureCache.getCachedImageWithRefresh(
                    for: user.id,
                    from: profilePictureUrl,
                    maxAge: 6 * 60 * 60 // 6 hours for more frequent updates
                )
            }
        }
    }
    
    /// Preload profile pictures for activity creators and participants
    private func preloadProfilePicturesForActivities(_ activities: [UUID: [FullFeedActivityDTO]]) async {
        let profilePictureCache = ProfilePictureCache.shared
        
        for (_, activityList) in activities {
            for activity in activityList {
                // Preload creator profile picture
                if let creatorPicture = activity.creatorUser.profilePicture {
                    _ = await profilePictureCache.getCachedImageWithRefresh(
                        for: activity.creatorUser.id,
                        from: creatorPicture,
                        maxAge: 6 * 60 * 60 // 6 hours
                    )
                }
                
                // Preload participant profile pictures
                if let participants = activity.participantUsers {
                    for participant in participants {
                        if let participantPicture = participant.profilePicture {
                            _ = await profilePictureCache.getCachedImageWithRefresh(
                                for: participant.id,
                                from: participantPicture,
                                maxAge: 6 * 60 * 60 // 6 hours
                            )
                        }
                    }
                }
                
                // Preload invited user profile pictures
                if let invitedUsers = activity.invitedUsers {
                    for invitedUser in invitedUsers {
                        if let invitedPicture = invitedUser.profilePicture {
                            _ = await profilePictureCache.getCachedImageWithRefresh(
                                for: invitedUser.id,
                                from: invitedPicture,
                                maxAge: 6 * 60 * 60 // 6 hours
                            )
                        }
                    }
                }
                
                // Preload chat message senders' profile pictures
                if let chatMessages = activity.chatMessages {
                    for chatMessage in chatMessages {
                        if let senderPicture = chatMessage.senderUser.profilePicture {
                            _ = await profilePictureCache.getCachedImageWithRefresh(
                                for: chatMessage.senderUser.id,
                                from: senderPicture,
                                maxAge: 6 * 60 * 60 // 6 hours
                            )
                        }
                    }
                }
            }
        }
    }
    
    /// Preload profile pictures for friend request senders
    private func preloadProfilePicturesForFriendRequests(_ friendRequests: [UUID: [FetchFriendRequestDTO]]) async {
        let profilePictureCache = ProfilePictureCache.shared
        
        for (_, requests) in friendRequests {
            for request in requests {
                if let senderPicture = request.senderUser.profilePicture {
                    _ = await profilePictureCache.getCachedImageWithRefresh(
                        for: request.senderUser.id,
                        from: senderPicture,
                        maxAge: 6 * 60 * 60 // 6 hours
                    )
                }
            }
        }
    }
    
    func refreshProfileStats(_ userId: UUID) async {
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh profile stats: No logged in user")
            return 
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot refresh profile stats: User is not logged in")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: myUserId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/\(userId)/stats") else { return }
            
            let stats: UserStatsDTO = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateProfileStats(userId, stats)
            }
        } catch {
            print("Failed to refresh profile stats: \(error.localizedDescription)")
        }
    }
    
    func refreshProfileInterests(_ userId: UUID) async {
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh profile interests: No logged in user")
            return 
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot refresh profile interests: User is not logged in")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: myUserId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/\(userId)/interests") else { return }
            
            let interests: [String] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateProfileInterests(userId, interests)
            }
        } catch {
            print("Failed to refresh profile interests: \(error.localizedDescription)")
        }
    }
    
    func refreshProfileSocialMedia(_ userId: UUID) async {
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh profile social media: No logged in user")
            return 
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot refresh profile social media: User is not logged in")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: myUserId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/\(userId)/social-media") else { return }
            
            let socialMedia: UserSocialMediaDTO = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateProfileSocialMedia(userId, socialMedia)
            }
        } catch {
            print("Failed to refresh profile social media: \(error.localizedDescription)")
        }
    }
    

    
    func refreshProfileActivities(_ userId: UUID) async {
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh profile activities: No logged in user")
            return 
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot refresh profile activities: User is not logged in")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: myUserId) : APIService()
            guard let url = URL(string: APIService.baseURL + "activities/profile/\(userId)") else { return }
            let parameters = ["requestingUserId": myUserId.uuidString]
            
            let activities: [ProfileActivityDTO] = try await apiService.fetchData(from: url, parameters: parameters)
            
            await MainActor.run {
                updateProfileActivities(userId, activities)
            }
        } catch {
            print("Failed to refresh profile activities: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Persistence
    
    private func loadFromDisk() {
        // Load cache timestamps (user-specific)
        if let timestampsData = UserDefaults.standard.data(forKey: CacheKeys.lastChecked),
           let loadedTimestamps = try? JSONDecoder().decode([UUID: [String: Date]].self, from: timestampsData) {
            lastChecked = loadedTimestamps
        }
        
        // Load friends
        if let friendsData = UserDefaults.standard.data(forKey: CacheKeys.friends),
           let loadedFriends = try? JSONDecoder().decode([UUID: [FullFriendUserDTO]].self, from: friendsData) {
            friends = loadedFriends
        }
        

        
        // Load activities
        if let activitiesData = UserDefaults.standard.data(forKey: CacheKeys.events),
           let loadedActivities = try? JSONDecoder().decode([UUID: [FullFeedActivityDTO]].self, from: activitiesData) {
            activities = loadedActivities
        }
        
        // Load activity types
        if let activityTypesData = UserDefaults.standard.data(forKey: CacheKeys.activityTypes),
           let loadedActivityTypes = try? JSONDecoder().decode([ActivityTypeDTO].self, from: activityTypesData) {
            activityTypes = loadedActivityTypes
        }
        
        // Load other profiles
        if let profilesData = UserDefaults.standard.data(forKey: CacheKeys.otherProfiles),
           let loadedProfiles = try? JSONDecoder().decode([UUID: BaseUserDTO].self, from: profilesData) {
            otherProfiles = loadedProfiles
        }
        
        // Load recommended friends
        if let recommendedData = UserDefaults.standard.data(forKey: CacheKeys.recommendedFriends),
           let loadedRecommended = try? JSONDecoder().decode([UUID: [RecommendedFriendUserDTO]].self, from: recommendedData) {
            recommendedFriends = loadedRecommended
        }
        
        // Load friend requests
        if let requestsData = UserDefaults.standard.data(forKey: CacheKeys.friendRequests),
           let loadedRequests = try? JSONDecoder().decode([UUID: [FetchFriendRequestDTO]].self, from: requestsData) {
            friendRequests = loadedRequests
        }
        
        // Load sent friend requests
        if let sentRequestsData = UserDefaults.standard.data(forKey: CacheKeys.sentFriendRequests),
           let loadedSentRequests = try? JSONDecoder().decode([UUID: [FetchFriendRequestDTO]].self, from: sentRequestsData) {
            sentFriendRequests = loadedSentRequests
        }
        
        // Load profile stats
        if let statsData = UserDefaults.standard.data(forKey: CacheKeys.profileStats),
           let loadedStats = try? JSONDecoder().decode([UUID: UserStatsDTO].self, from: statsData) {
            profileStats = loadedStats
        }
        
        // Load profile interests
        if let interestsData = UserDefaults.standard.data(forKey: CacheKeys.profileInterests),
           let loadedInterests = try? JSONDecoder().decode([UUID: [String]].self, from: interestsData) {
            profileInterests = loadedInterests
        }
        
        // Load profile social media
        if let socialMediaData = UserDefaults.standard.data(forKey: CacheKeys.profileSocialMedia),
           let loadedSocialMedia = try? JSONDecoder().decode([UUID: UserSocialMediaDTO].self, from: socialMediaData) {
            profileSocialMedia = loadedSocialMedia
        }
        

        
        // Load profile activities
        if let activitiesData = UserDefaults.standard.data(forKey: CacheKeys.profileEvents),
           let loadedActivities = try? JSONDecoder().decode([UUID: [ProfileActivityDTO]].self, from: activitiesData) {
            profileActivities = loadedActivities
        }
    }
    
    private func saveToDisk() {
        // Save cache timestamps (user-specific)
        if let timestampsData = try? JSONEncoder().encode(lastChecked) {
            UserDefaults.standard.set(timestampsData, forKey: CacheKeys.lastChecked)
        }
        
        // Save friends
        if let friendsData = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(friendsData, forKey: CacheKeys.friends)
        }
        

        
        // Save activities
        if let activitiesData = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(activitiesData, forKey: CacheKeys.events)
        }
        
        // Save activity types
        if let activityTypesData = try? JSONEncoder().encode(activityTypes) {
            UserDefaults.standard.set(activityTypesData, forKey: CacheKeys.activityTypes)
        }
        
        // Save other profiles
        if let profilesData = try? JSONEncoder().encode(otherProfiles) {
            UserDefaults.standard.set(profilesData, forKey: CacheKeys.otherProfiles)
        }
        
        // Save recommended friends
        if let recommendedData = try? JSONEncoder().encode(recommendedFriends) {
            UserDefaults.standard.set(recommendedData, forKey: CacheKeys.recommendedFriends)
        }
        
        // Save friend requests
        if let requestsData = try? JSONEncoder().encode(friendRequests) {
            UserDefaults.standard.set(requestsData, forKey: CacheKeys.friendRequests)
        }
        
        // Save sent friend requests
        if let sentRequestsData = try? JSONEncoder().encode(sentFriendRequests) {
            UserDefaults.standard.set(sentRequestsData, forKey: CacheKeys.sentFriendRequests)
        }
        
        // Save profile stats
        if let statsData = try? JSONEncoder().encode(profileStats) {
            UserDefaults.standard.set(statsData, forKey: CacheKeys.profileStats)
        }
        
        // Save profile interests
        if let interestsData = try? JSONEncoder().encode(profileInterests) {
            UserDefaults.standard.set(interestsData, forKey: CacheKeys.profileInterests)
        }
        
        // Save profile social media
        if let socialMediaData = try? JSONEncoder().encode(profileSocialMedia) {
            UserDefaults.standard.set(socialMediaData, forKey: CacheKeys.profileSocialMedia)
        }
        

        
        // Save profile activities
        if let activitiesData = try? JSONEncoder().encode(profileActivities) {
            UserDefaults.standard.set(activitiesData, forKey: CacheKeys.profileEvents)
        }
    }
} 
