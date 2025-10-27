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
    
    // MARK: - Background Queue for Disk Operations
    private let diskQueue = DispatchQueue(label: "com.spawn.appCache.diskQueue", qos: .utility)
    private var pendingSaveTask: DispatchWorkItem?
    private let saveDebounceInterval: TimeInterval = 1.0 // Debounce saves to reduce frequency
    
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
        // Load from disk in the background to avoid blocking main thread
        diskQueue.async { [weak self] in
            self?.loadFromDisk()
        }
        
        // Set up a timer to periodically save to disk (debounced)
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.debouncedSaveToDisk()
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
    
    // MARK: - Helper Methods
    
    /// No-op async function for conditional parallel execution
    private func noop() async {
        // Does nothing - used for conditional async let statements
    }
    
    /// Generic refresh function to reduce code duplication
    private func genericRefresh<T: Decodable>(
        endpoint: String,
        parameters: [String: String]? = nil,
        updateCache: @escaping ([T]) -> Void
    ) async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("Cannot refresh \(endpoint): No logged in user")
            return
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot refresh \(endpoint): User is not logged in")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + endpoint) else { return }
            
            let fetchedData: [T] = try await apiService.fetchData(from: url, parameters: parameters)
            
            await MainActor.run {
                updateCache(fetchedData)
            }
        } catch {
            print("Failed to refresh \(endpoint): \(error.localizedDescription)")
        }
    }
    
    /// Generic single item refresh function
    private func genericSingleRefresh<T: Decodable>(
        endpoint: String,
        parameters: [String: String]? = nil,
        updateCache: @escaping (T) -> Void
    ) async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("Cannot refresh \(endpoint): No logged in user")
            return
        }
        
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot refresh \(endpoint): User is not logged in")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + endpoint) else { return }
            
            let fetchedData: T = try await apiService.fetchData(from: url, parameters: parameters)
            
            await MainActor.run {
                updateCache(fetchedData)
            }
        } catch {
            print("Failed to refresh \(endpoint): \(error.localizedDescription)")
        }
    }
    
    /// Generic update function with timestamp and save
    private func genericUpdate<T>(
        _ data: T,
        to keyPath: ReferenceWritableKeyPath<AppCache, T>,
        cacheKey: String
    ) {
        self[keyPath: keyPath] = data
        
        if let userId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(userId, cacheType: cacheKey, date: Date())
        }
        
        debouncedSaveToDisk()
    }
    
    /// Generic encode-save helper
    private func saveToDefaults<T: Encodable>(_ data: T, key: String) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    /// Generic decode-load helper
    private func loadFromDefaults<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    // MARK: - Public Methods
    
    /// Initialize the cache and load from disk in the background
    func initialize() {
        if !isInitialized {
            diskQueue.async { [weak self] in
                self?.loadFromDisk()
                self?.isInitialized = true
            }
        }
    }
    
    /// Clear all cached data and reset the cache state
    func clearAllCaches() {
        // Clear all cached data (on main thread since these are @Published)
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
        
        // Clear UserDefaults data on background queue to avoid blocking main thread
        diskQueue.async {
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
            
            print("✅ [CACHE] All UserDefaults cleared on background thread")
        }
        
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

        // If we have no cached items to validate for this user, request fresh data for all cache types
        if userLastChecked.isEmpty {
            print("🔄 [CACHE] No cached items to validate, requesting fresh data for all cache types")
            // Request fresh data for all standard cache types
			async let friendsTask: () = refreshFriends()
			async let activitiesTask: () = refreshActivities()
			async let activityTypesTask: () = refreshActivityTypes()
			async let recommendedFriendsTask: () = refreshRecommendedFriends()
			async let friendRequestsTask: () = refreshFriendRequests()
			async let sentFriendRequestsTask: () = refreshSentFriendRequests()

			// Wait for all tasks to complete
			let _ = await (friendsTask, activitiesTask, activityTypesTask, recommendedFriendsTask, friendRequestsTask, sentFriendRequestsTask)

			// Clean up any expired activities after refresh
			cleanupExpiredActivities()

			print("✅ [CACHE] Completed initial cache refresh for all cache types")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            let result = try await apiService.validateCache(userLastChecked)
            
            await MainActor.run {
                // Track which caches need refreshing for parallel execution
                var needsFriendsRefresh = false
                var needsActivitiesRefresh = false
                var needsActivityTypesRefresh = false
                var needsOtherProfilesRefresh = false
                var needsRecommendedFriendsRefresh = false
                var needsFriendRequestsRefresh = false
                var needsSentFriendRequestsRefresh = false
                
                // Update each collection based on invalidation results
                if let friendsResponse = result[CacheKeys.friends], friendsResponse.invalidate {
                    if let updatedItems = friendsResponse.updatedItems,
                       let updatedFriends = try? JSONDecoder().decode([UUID: [FullFriendUserDTO]].self, from: updatedItems) {
                        // Backend provided the updated data
                        updateFriends(updatedFriends)
                    } else {
                        needsFriendsRefresh = true
                    }
                }
                
                if let activitiesResponse = result[CacheKeys.events], activitiesResponse.invalidate {
                    if let updatedItems = activitiesResponse.updatedItems,
                       let updatedActivities = try? JSONDecoder().decode([UUID: [FullFeedActivityDTO]].self, from: updatedItems) {
                        // Backend provided the updated data - filter expired activities before updating
                        var filteredUpdatedActivities: [UUID: [FullFeedActivityDTO]] = [:]
                        for (userId, userActivities) in updatedActivities {
                            filteredUpdatedActivities[userId] = userActivities.filter { activity in
                                return activity.isExpired != true
                            }
                        }
                        updateActivities(filteredUpdatedActivities)
                    } else {
                        needsActivitiesRefresh = true
                    }
                }
                
                // Activity Types Cache
                if let activityTypesResponse = result[CacheKeys.activityTypes], activityTypesResponse.invalidate {
                    if let updatedItems = activityTypesResponse.updatedItems,
                       let updatedActivityTypes = try? JSONDecoder().decode([ActivityTypeDTO].self, from: updatedItems) {
                        // Backend provided the updated data
                        updateActivityTypes(updatedActivityTypes)
                    } else {
                        needsActivityTypesRefresh = true
                    }
                }
                
                // Other Profiles Cache
                if let otherProfilesResponse = result[CacheKeys.otherProfiles], otherProfilesResponse.invalidate {
                    needsOtherProfilesRefresh = true
                }
                
                // Recommended Friends Cache
                if let recommendedFriendsResponse = result[CacheKeys.recommendedFriends], recommendedFriendsResponse.invalidate {
                    if let updatedItems = recommendedFriendsResponse.updatedItems,
                       let updatedRecommendedFriends = try? JSONDecoder().decode([UUID: [RecommendedFriendUserDTO]].self, from: updatedItems) {
                        updateRecommendedFriends(updatedRecommendedFriends)
                    } else {
                        needsRecommendedFriendsRefresh = true
                    }
                }
                
                // Friend Requests Cache
                if let friendRequestsResponse = result[CacheKeys.friendRequests], friendRequestsResponse.invalidate {
                    if let updatedItems = friendRequestsResponse.updatedItems,
                       let updatedFriendRequests = try? JSONDecoder().decode([UUID: [FetchFriendRequestDTO]].self, from: updatedItems) {
                        updateFriendRequests(updatedFriendRequests)
                    } else {
                        needsFriendRequestsRefresh = true
                    }
                }
                
                // Sent Friend Requests Cache
                if let sentFriendRequestsResponse = result[CacheKeys.sentFriendRequests], sentFriendRequestsResponse.invalidate {
                    if let updatedItems = sentFriendRequestsResponse.updatedItems,
                       let updatedSentFriendRequests = try? JSONDecoder().decode([UUID: [FetchSentFriendRequestDTO]].self, from: updatedItems) {
                        updateSentFriendRequests(updatedSentFriendRequests)
                    } else {
                        needsSentFriendRequestsRefresh = true
                    }
                }
                
                // Refresh all invalidated caches in parallel for faster performance
                if needsFriendsRefresh || needsActivitiesRefresh || needsActivityTypesRefresh || 
                   needsOtherProfilesRefresh || needsRecommendedFriendsRefresh || 
                   needsFriendRequestsRefresh || needsSentFriendRequestsRefresh {
                    Task {
                        async let friendsTask: () = needsFriendsRefresh ? refreshFriends() : noop()
                        async let activitiesTask: () = needsActivitiesRefresh ? refreshActivities() : noop()
                        async let activityTypesTask: () = needsActivityTypesRefresh ? refreshActivityTypes() : noop()
                        async let otherProfilesTask: () = needsOtherProfilesRefresh ? refreshOtherProfiles() : noop()
                        async let recommendedFriendsTask: () = needsRecommendedFriendsRefresh ? refreshRecommendedFriends() : noop()
                        async let friendRequestsTask: () = needsFriendRequestsRefresh ? refreshFriendRequests() : noop()
                        async let sentFriendRequestsTask: () = needsSentFriendRequestsRefresh ? refreshSentFriendRequests() : noop()
                        
                        let _ = await (friendsTask, activitiesTask, activityTypesTask, otherProfilesTask, recommendedFriendsTask, friendRequestsTask, sentFriendRequestsTask)
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
        
        debouncedSaveToDisk()
        
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
        
        await genericRefresh(endpoint: "users/friends/\(userId)") { (fetchedFriends: [FullFriendUserDTO]) in
            self.updateFriendsForUser(fetchedFriends, userId: userId)
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
        
        debouncedSaveToDisk()
        
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
        
        await genericRefresh(endpoint: "activities/feedActivities/\(userId)") { (fetchedActivities: [FullFeedActivityDTO]) in
            self.updateActivitiesForUser(fetchedActivities, userId: userId)
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
        debouncedSaveToDisk()
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
        debouncedSaveToDisk()
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
        
        debouncedSaveToDisk()
    }
    
    func refreshActivityTypes() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh activity types: No logged in user")
            return 
        }
        
        await genericRefresh(endpoint: "users/\(userId)/activity-types") { (fetchedActivityTypes: [ActivityTypeDTO]) in
            self.updateActivityTypes(fetchedActivityTypes)
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
        
        debouncedSaveToDisk()
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
        
        debouncedSaveToDisk()
    }
    
    // MARK: - Other Profiles Methods
    
    func updateOtherProfile(_ userId: UUID, _ profile: BaseUserDTO) {
        otherProfiles[userId] = profile
        
        // Update timestamp for current user
        if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(currentUserId, cacheType: CacheKeys.otherProfiles, date: Date())
        }
        
        debouncedSaveToDisk()
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
            debouncedSaveToDisk()
        }
    }
    
    // MARK: - Recommended Friends Methods
    
    func updateRecommendedFriends(_ newRecommendedFriends: [UUID: [RecommendedFriendUserDTO]]) {
        recommendedFriends = newRecommendedFriends
        
        // Update timestamp for current user
        if let userId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(userId, cacheType: CacheKeys.recommendedFriends, date: Date())
        }
        
        debouncedSaveToDisk()
        
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
        
        await genericRefresh(endpoint: "users/recommended-friends/\(userId)") { (fetchedRecommendedFriends: [RecommendedFriendUserDTO]) in
            self.updateRecommendedFriendsForUser(fetchedRecommendedFriends, userId: userId)
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
        debouncedSaveToDisk()
        
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
        
        debouncedSaveToDisk()
        
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
        
        await genericRefresh(endpoint: "friend-requests/incoming/\(userId)") { (fetchedFriendRequests: [FetchFriendRequestDTO]) in
            print("🔄 [CACHE] Retrieved \(fetchedFriendRequests.count) incoming friend requests from API")
            self.updateFriendRequestsForUser(fetchedFriendRequests, userId: userId)
        }
    }

    /// Clear friend requests for a specific user (useful when user logs out or switches)
    func clearFriendRequestsForUser(_ userId: UUID) {
        friendRequests.removeValue(forKey: userId)
        debouncedSaveToDisk()
    }
    
    // MARK: - Sent Friend Requests Methods

    /// Get sent friend requests for the current user
    func getCurrentUserSentFriendRequests() -> [FetchSentFriendRequestDTO] {
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
        debouncedSaveToDisk()
        
        // Preload profile pictures for sent friend request receivers
        Task {
            await preloadProfilePicturesForSentFriendRequests([userId: normalized])
        }
    }

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
        
        debouncedSaveToDisk()
        
        // Preload profile pictures for sent friend request receivers
        Task {
            await preloadProfilePicturesForSentFriendRequests(normalizedMap)
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
        
        await genericRefresh(endpoint: "friend-requests/sent/\(userId)") { (fetchedSentFriendRequests: [FetchSentFriendRequestDTO]) in
            print("🔄 [CACHE] Retrieved \(fetchedSentFriendRequests.count) sent friend requests from API")
            self.updateSentFriendRequestsForUser(fetchedSentFriendRequests, userId: userId)
        }
    }

    /// Clear sent friend requests for a specific user (useful when user logs out or switches)
    func clearSentFriendRequestsForUser(_ userId: UUID) {
        sentFriendRequests.removeValue(forKey: userId)
        debouncedSaveToDisk()
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
        let uniqueUsers = usersToRefresh.compactMap { (user: (userId: UUID, profilePictureUrl: String?)) -> (userId: UUID, profilePictureUrl: String?)? in
            guard !seen.contains(user.userId) else { return nil }
            seen.insert(user.userId)
            return user
        }
        
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
        let uniqueUsers = usersToRefresh.compactMap { (user: (userId: UUID, profilePictureUrl: String?)) -> (userId: UUID, profilePictureUrl: String?)? in
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
        debouncedSaveToDisk()
        
        // Preload profile pictures for friends
        Task {
            await preloadProfilePictures(for: [userId: newFriends])
        }
    }
    
    /// Clear friends for a specific user
    func clearFriendsForUser(_ userId: UUID) {
        friends.removeValue(forKey: userId)
        debouncedSaveToDisk()
    }
    
    /// Get activities for the current user, filtering out expired ones
    func getCurrentUserActivities() -> [FullFeedActivityDTO] {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return [] }
        let userActivities = activities[userId] ?? []
        
        // Filter out expired activities based on server-side expiration status
        let filteredActivities = userActivities.filter { activity in
            return activity.isExpired != true
        }
        
        // If we filtered out expired activities, update the cache to remove them
        if filteredActivities.count != userActivities.count {
            activities[userId] = filteredActivities
            debouncedSaveToDisk()
        }
        
        return filteredActivities
    }
    
    /// Update activities for a specific user
    func updateActivitiesForUser(_ newActivities: [FullFeedActivityDTO], userId: UUID) {
        // Filter out expired activities before storing in cache
        let filteredActivities = newActivities.filter { activity in
            return activity.isExpired != true
        }
        
        activities[userId] = filteredActivities
        setLastCheckedForUser(userId, cacheType: CacheKeys.events, date: Date())
        
        // Pre-assign colors for even distribution
        let activityIds = filteredActivities.map { $0.id }
        ActivityColorService.shared.assignColorsForActivities(activityIds)
        
        debouncedSaveToDisk()
        
        // Preload profile pictures for activities
        Task {
            await preloadProfilePicturesForActivities([userId: filteredActivities])
        }
    }
    
    /// Clear activities for a specific user
    func clearActivitiesForUser(_ userId: UUID) {
        activities.removeValue(forKey: userId)
        debouncedSaveToDisk()
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
            debouncedSaveToDisk()
            print("🧹 [CACHE] Cleaned up expired activities from cache")
        }
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
        debouncedSaveToDisk()
        
        // Preload profile pictures for recommended friends
        Task {
            await preloadProfilePictures(for: [userId: newRecommendedFriends])
        }
    }
    
    /// Clear recommended friends for a specific user
    func clearRecommendedFriendsForUser(_ userId: UUID) {
        recommendedFriends.removeValue(forKey: userId)
        debouncedSaveToDisk()
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
        debouncedSaveToDisk()
    }
    
    // MARK: - Profile Methods
    
    func updateProfileStats(_ userId: UUID, _ stats: UserStatsDTO) {
        profileStats[userId] = stats
        
        // Update timestamp for current user
        if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(currentUserId, cacheType: CacheKeys.profileStats, date: Date())
        }
        
        debouncedSaveToDisk()
    }
    
    func updateProfileInterests(_ userId: UUID, _ interests: [String]) {
        profileInterests[userId] = interests
        
        // Update timestamp for current user
        if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(currentUserId, cacheType: CacheKeys.profileInterests, date: Date())
        }
        
        debouncedSaveToDisk()
    }
    
    func updateProfileSocialMedia(_ userId: UUID, _ socialMedia: UserSocialMediaDTO) {
        profileSocialMedia[userId] = socialMedia
        
        // Update timestamp for current user
        if let currentUserId = UserAuthViewModel.shared.spawnUser?.id {
            setLastCheckedForUser(currentUserId, cacheType: CacheKeys.profileSocialMedia, date: Date())
        }
        
        debouncedSaveToDisk()
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
        
        debouncedSaveToDisk()
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
    /// Uses task groups to download multiple profile pictures in parallel for faster performance
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
                                maxAge: 6 * 60 * 60 // 6 hours
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
                                        maxAge: 6 * 60 * 60 // 6 hours
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
                                        maxAge: 6 * 60 * 60 // 6 hours
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
                                        maxAge: 6 * 60 * 60 // 6 hours
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Preload profile pictures for friend request senders
    /// Uses task groups to download multiple profile pictures in parallel for faster performance
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
                                maxAge: 6 * 60 * 60 // 6 hours
                            )
                        }
                    }
                }
            }
        }
    }
    
    /// Preload profile pictures for sent friend request receivers
    /// Uses task groups to download multiple profile pictures in parallel for faster performance
    private func preloadProfilePicturesForSentFriendRequests(_ sentFriendRequests: [UUID: [FetchSentFriendRequestDTO]]) async {
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
                                maxAge: 6 * 60 * 60 // 6 hours
                            )
                        }
                    }
                }
            }
        }
    }
    
    func refreshProfileStats(_ userId: UUID) async {
        await genericSingleRefresh(endpoint: "users/\(userId)/stats") { (stats: UserStatsDTO) in
            self.updateProfileStats(userId, stats)
        }
    }
    
    func refreshProfileInterests(_ userId: UUID) async {
        await genericRefresh(endpoint: "users/\(userId)/interests") { (interests: [String]) in
            self.updateProfileInterests(userId, interests)
        }
    }
    
    func refreshProfileSocialMedia(_ userId: UUID) async {
        await genericSingleRefresh(endpoint: "users/\(userId)/social-media") { (socialMedia: UserSocialMediaDTO) in
            self.updateProfileSocialMedia(userId, socialMedia)
        }
    }

    
    func refreshProfileActivities(_ userId: UUID) async {
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh profile activities: No logged in user")
            return 
        }
        
        let parameters = ["requestingUserId": myUserId.uuidString]
        await genericRefresh(endpoint: "activities/profile/\(userId)", parameters: parameters) { (activities: [ProfileActivityDTO]) in
            self.updateProfileActivities(userId, activities)
        }
    }
    
    // MARK: - Persistence
    
    /// Debounced save that prevents excessive disk writes
    /// Captures data on main thread, then encodes on background thread
    private func debouncedSaveToDisk() {
        // Cancel any pending save task
        pendingSaveTask?.cancel()
        
        // Capture current state on main thread (must read @Published properties on main thread)
        let capturedTimestamps = self.lastChecked
        let capturedFriends = self.friends
        let capturedActivities = self.activities
        let capturedActivityTypes = self.activityTypes
        let capturedOtherProfiles = self.otherProfiles
        let capturedRecommendedFriends = self.recommendedFriends
        let capturedFriendRequests = self.friendRequests
        let capturedSentFriendRequests = self.sentFriendRequests
        let capturedProfileStats = self.profileStats
        let capturedProfileInterests = self.profileInterests
        let capturedProfileSocialMedia = self.profileSocialMedia
        let capturedProfileActivities = self.profileActivities
        
        // Create a new save task that encodes and writes on background queue
        let task = DispatchWorkItem { [weak self] in
            self?.performSaveToDisk(
                timestamps: capturedTimestamps,
                friends: capturedFriends,
                activities: capturedActivities,
                activityTypes: capturedActivityTypes,
                otherProfiles: capturedOtherProfiles,
                recommendedFriends: capturedRecommendedFriends,
                friendRequests: capturedFriendRequests,
                sentFriendRequests: capturedSentFriendRequests,
                profileStats: capturedProfileStats,
                profileInterests: capturedProfileInterests,
                profileSocialMedia: capturedProfileSocialMedia,
                profileActivities: capturedProfileActivities
            )
        }
        
        // Store the task and schedule it
        pendingSaveTask = task
        diskQueue.asyncAfter(deadline: .now() + saveDebounceInterval, execute: task)
    }
    
    /// Immediately save to disk (captures on main thread, encodes on background)
    private func immediateSaveToDisk() {
        // Capture current state on main thread
        let capturedTimestamps = self.lastChecked
        let capturedFriends = self.friends
        let capturedActivities = self.activities
        let capturedActivityTypes = self.activityTypes
        let capturedOtherProfiles = self.otherProfiles
        let capturedRecommendedFriends = self.recommendedFriends
        let capturedFriendRequests = self.friendRequests
        let capturedSentFriendRequests = self.sentFriendRequests
        let capturedProfileStats = self.profileStats
        let capturedProfileInterests = self.profileInterests
        let capturedProfileSocialMedia = self.profileSocialMedia
        let capturedProfileActivities = self.profileActivities
        
        // Encode and write on background queue
        diskQueue.async { [weak self] in
            self?.performSaveToDisk(
                timestamps: capturedTimestamps,
                friends: capturedFriends,
                activities: capturedActivities,
                activityTypes: capturedActivityTypes,
                otherProfiles: capturedOtherProfiles,
                recommendedFriends: capturedRecommendedFriends,
                friendRequests: capturedFriendRequests,
                sentFriendRequests: capturedSentFriendRequests,
                profileStats: capturedProfileStats,
                profileInterests: capturedProfileInterests,
                profileSocialMedia: capturedProfileSocialMedia,
                profileActivities: capturedProfileActivities
            )
        }
    }
    
    private func loadFromDisk() {
        // This method should only be called from diskQueue (background thread)
        // Decode all data on background thread, then update @Published properties on main thread
        
        let loadedTimestamps: [UUID: [String: Date]]? = loadFromDefaults(key: CacheKeys.lastChecked)
        let loadedFriends: [UUID: [FullFriendUserDTO]]? = loadFromDefaults(key: CacheKeys.friends)
        let loadedActivities: [UUID: [FullFeedActivityDTO]]? = loadFromDefaults(key: CacheKeys.events)
        let loadedActivityTypes: [ActivityTypeDTO]? = loadFromDefaults(key: CacheKeys.activityTypes)
        let loadedProfiles: [UUID: BaseUserDTO]? = loadFromDefaults(key: CacheKeys.otherProfiles)
        let loadedRecommended: [UUID: [RecommendedFriendUserDTO]]? = loadFromDefaults(key: CacheKeys.recommendedFriends)
        let loadedRequests: [UUID: [FetchFriendRequestDTO]]? = loadFromDefaults(key: CacheKeys.friendRequests)
        let loadedSentRequests: [UUID: [FetchSentFriendRequestDTO]]? = loadFromDefaults(key: CacheKeys.sentFriendRequests)
        let loadedStats: [UUID: UserStatsDTO]? = loadFromDefaults(key: CacheKeys.profileStats)
        let loadedInterests: [UUID: [String]]? = loadFromDefaults(key: CacheKeys.profileInterests)
        let loadedSocialMedia: [UUID: UserSocialMediaDTO]? = loadFromDefaults(key: CacheKeys.profileSocialMedia)
        let loadedProfileActivities: [UUID: [ProfileActivityDTO]]? = loadFromDefaults(key: CacheKeys.profileEvents)
        
        // Now update @Published properties on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let timestamps = loadedTimestamps { self.lastChecked = timestamps }
            if let friends = loadedFriends { self.friends = friends }
            if let activities = loadedActivities { self.activities = activities }
            if let types = loadedActivityTypes { self.activityTypes = types }
            if let profiles = loadedProfiles { self.otherProfiles = profiles }
            if let recommended = loadedRecommended { self.recommendedFriends = recommended }
            if let requests = loadedRequests { self.friendRequests = requests }
            if let sentRequests = loadedSentRequests { self.sentFriendRequests = sentRequests }
            if let stats = loadedStats { self.profileStats = stats }
            if let interests = loadedInterests { self.profileInterests = interests }
            if let socialMedia = loadedSocialMedia { self.profileSocialMedia = socialMedia }
            if let profileActivities = loadedProfileActivities { self.profileActivities = profileActivities }
            
            print("✅ [CACHE] Loaded all data from disk on background thread")
        }
    }
    
    private func saveToDisk() {
        // This method is called from diskQueue (background thread)
        // NO operations here - all work done in debouncedSaveToDisk which captures data properly
        print("⚠️ [CACHE] saveToDisk called directly - should use debouncedSaveToDisk or immediateSaveToDisk")
    }
    
    /// Actual save implementation that safely captures data on main thread before encoding on background
    private func performSaveToDisk(
        timestamps: [UUID: [String: Date]],
        friends: [UUID: [FullFriendUserDTO]],
        activities: [UUID: [FullFeedActivityDTO]],
        activityTypes: [ActivityTypeDTO],
        otherProfiles: [UUID: BaseUserDTO],
        recommendedFriends: [UUID: [RecommendedFriendUserDTO]],
        friendRequests: [UUID: [FetchFriendRequestDTO]],
        sentFriendRequests: [UUID: [FetchSentFriendRequestDTO]],
        profileStats: [UUID: UserStatsDTO],
        profileInterests: [UUID: [String]],
        profileSocialMedia: [UUID: UserSocialMediaDTO],
        profileActivities: [UUID: [ProfileActivityDTO]]
    ) {
        // All encoding and disk writes happen on background thread (diskQueue)
        saveToDefaults(timestamps, key: CacheKeys.lastChecked)
        saveToDefaults(friends, key: CacheKeys.friends)
        saveToDefaults(activities, key: CacheKeys.events)
        saveToDefaults(activityTypes, key: CacheKeys.activityTypes)
        saveToDefaults(otherProfiles, key: CacheKeys.otherProfiles)
        saveToDefaults(recommendedFriends, key: CacheKeys.recommendedFriends)
        saveToDefaults(friendRequests, key: CacheKeys.friendRequests)
        saveToDefaults(sentFriendRequests, key: CacheKeys.sentFriendRequests)
        saveToDefaults(profileStats, key: CacheKeys.profileStats)
        saveToDefaults(profileInterests, key: CacheKeys.profileInterests)
        saveToDefaults(profileSocialMedia, key: CacheKeys.profileSocialMedia)
        saveToDefaults(profileActivities, key: CacheKeys.profileEvents)
    }
} 
