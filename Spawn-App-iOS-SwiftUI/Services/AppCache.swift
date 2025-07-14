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
    @Published var friends: [FullFriendUserDTO] = []
    @Published var activities: [FullFeedActivityDTO] = []
    @Published var activityTypes: [ActivityTypeDTO] = []
    @Published var recommendedFriends: [RecommendedFriendUserDTO] = []
    @Published var friendRequests: [UUID: [FetchFriendRequestDTO]] = [:]  // Changed to be user-specific
    @Published var otherProfiles: [UUID: BaseUserDTO] = [:]
    
    // Profile caches
    @Published var profileStats: [UUID: UserStatsDTO] = [:]
    @Published var profileInterests: [UUID: [String]] = [:]
    @Published var profileSocialMedia: [UUID: UserSocialMediaDTO] = [:]
    @Published var profileActivities: [UUID: [ProfileActivityDTO]] = [:]
    
    // MARK: - Cache Metadata
    private var lastChecked: [String: Date] = [:]
    private var isInitialized = false
    
    // MARK: - Constants
    private enum CacheKeys {
        static let lastChecked = "lastChecked"
        static let friends = "friends"
        static let events = "events"  // Changed from "activities" to match backend
        static let activityTypes = "activityTypes"
        static let recommendedFriends = "recommendedFriends"
        static let friendRequests = "friendRequests"
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
        friends = []
        activities = []
        activityTypes = []
        recommendedFriends = []
        friendRequests = [:] // Clear user-specific friend requests
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
            print("Cannot validate cache: No logged in user")
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
        
        // Don't send validation request if we have no cached items to validate
        if lastChecked.isEmpty {
            print("No cached items to validate, skipping cache validation")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            let result = try await apiService.validateCache(lastChecked)
            
            await MainActor.run {
                // Update each collection based on invalidation results
                if let friendsResponse = result[CacheKeys.friends], friendsResponse.invalidate {
                    if let updatedItems = friendsResponse.updatedItems,
                       let updatedFriends = try? JSONDecoder().decode([FullFriendUserDTO].self, from: updatedItems) {
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
                       let updatedActivities = try? JSONDecoder().decode([FullFeedActivityDTO].self, from: updatedItems) {
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
                       let updatedRecommendedFriends = try? JSONDecoder().decode([RecommendedFriendUserDTO].self, from: updatedItems) {
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
            }
            
        } catch {
            print("Failed to validate cache: \(error.localizedDescription)")
            // If validation fails, we'll continue using cached data
        }
    }
    
    // MARK: - Friends Methods
    
    func updateFriends(_ newFriends: [FullFriendUserDTO]) {
        friends = newFriends
        lastChecked[CacheKeys.friends] = Date()
        saveToDisk()
        
        // Preload profile pictures for friends
        Task {
            await preloadProfilePictures(for: newFriends)
        }
    }
    
    func refreshFriends() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/friends/\(userId)") else { return }
            
            let fetchedFriends: [FullFriendUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateFriends(fetchedFriends)
            }
        } catch {
            print("Failed to refresh friends: \(error.localizedDescription)")
        }
    }
    

    
    // MARK: - Activities Methods
    
    func updateActivities(_ newActivities: [FullFeedActivityDTO]) {
        activities = newActivities
        lastChecked[CacheKeys.events] = Date()
        
        // Pre-assign colors for even distribution
        let activityIds = newActivities.map { $0.id }
        ActivityColorService.shared.assignColorsForActivities(activityIds)
        
        saveToDisk()
        
        // Preload profile pictures for activity creators and participants
        Task {
            await preloadProfilePicturesForActivities(newActivities)
        }
    }
    
    func refreshActivities() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "activities/feedActivities/\(userId)") else { return }
            
            let fetchedActivities: [FullFeedActivityDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateActivities(fetchedActivities)
            }
        } catch {
            print("Failed to refresh activities: \(error.localizedDescription)")
        }
    }
    
    // Get an activity by ID from the cache
    func getActivityById(_ activityId: UUID) -> FullFeedActivityDTO? {
        return activities.first { $0.id == activityId }
    }
    
    // Add or update an activity in the cache
    func addOrUpdateActivity(_ activity: FullFeedActivityDTO) {
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index] = activity
        } else {
            activities.append(activity)
        }
        
        // Ensure color is assigned for the activity
        ActivityColorService.shared.assignColorsForActivities([activity.id])
        
        lastChecked[CacheKeys.events] = Date()
        saveToDisk()
    }
    
    // Remove an activity from the cache
    func removeActivity(_ activityId: UUID) {
        activities.removeAll { $0.id == activityId }
        lastChecked[CacheKeys.events] = Date()
        saveToDisk()
    }
    
    /// Optimistically updates an activity in the cache
    func optimisticallyUpdateActivity(_ activity: FullFeedActivityDTO) {
        addOrUpdateActivity(activity)
    }
    
    // MARK: - Activity Types Methods
    
    func updateActivityTypes(_ newActivityTypes: [ActivityTypeDTO]) {
        activityTypes = newActivityTypes
        lastChecked[CacheKeys.activityTypes] = Date()
        saveToDisk()
    }
    
    func refreshActivityTypes() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "\(userId)/activity-types") else { return }
            
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
        lastChecked[CacheKeys.activityTypes] = Date()
        saveToDisk()
    }
    
    // Update a single activity type in the cache (for optimistic updates)
    func updateActivityTypeInCache(_ activityTypeDTO: ActivityTypeDTO) {
        if let index = activityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
            activityTypes[index] = activityTypeDTO
        } else {
            activityTypes.append(activityTypeDTO)
        }
        lastChecked[CacheKeys.activityTypes] = Date()
        saveToDisk()
    }
    
    // MARK: - Other Profiles Methods
    
    func updateOtherProfile(_ userId: UUID, _ profile: BaseUserDTO) {
        otherProfiles[userId] = profile
        lastChecked[CacheKeys.otherProfiles] = Date()
        saveToDisk()
    }
    
    func refreshOtherProfiles() async {
        // Since this is a collection of individual profiles,
        // we'll refresh all the profiles we currently have cached
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
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
            lastChecked[CacheKeys.otherProfiles] = Date()
            saveToDisk()
        }
    }
    
    // MARK: - Recommended Friends Methods
    
    func updateRecommendedFriends(_ newRecommendedFriends: [RecommendedFriendUserDTO]) {
        recommendedFriends = newRecommendedFriends
        lastChecked[CacheKeys.recommendedFriends] = Date()
        saveToDisk()
        
        // Preload profile pictures for recommended friends
        Task {
            await preloadProfilePictures(for: newRecommendedFriends)
        }
    }
    
    func refreshRecommendedFriends() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/recommended-friends/\(userId)") else { return }
            
            let fetchedRecommendedFriends: [RecommendedFriendUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateRecommendedFriends(fetchedRecommendedFriends)
            }
        } catch {
            print("Failed to refresh recommended friends: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Friend Requests Methods

    /// Get friend requests for the current user
    func getCurrentUserFriendRequests() -> [FetchFriendRequestDTO] {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return [] }
        return friendRequests[userId] ?? []
    }

    /// Update friend requests for a specific user
    func updateFriendRequestsForUser(_ newFriendRequests: [FetchFriendRequestDTO], userId: UUID) {
        friendRequests[userId] = newFriendRequests
        lastChecked[CacheKeys.friendRequests] = Date()
        saveToDisk()
        
        // Preload profile pictures for friend request senders
        Task {
            await preloadProfilePicturesForFriendRequests([userId: newFriendRequests])
        }
    }

    func updateFriendRequests(_ newFriendRequests: [UUID: [FetchFriendRequestDTO]]) {
        friendRequests = newFriendRequests
        lastChecked[CacheKeys.friendRequests] = Date()
        saveToDisk()
        
        // Preload profile pictures for friend request senders
        Task {
            await preloadProfilePicturesForFriendRequests(newFriendRequests)
        }
    }

    func refreshFriendRequests() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "friend-requests/incoming/\(userId)") else { return }
            
            let fetchedFriendRequests: [FetchFriendRequestDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateFriendRequestsForUser(fetchedFriendRequests, userId: userId)
            }
        } catch {
            print("Failed to refresh friend requests: \(error.localizedDescription)")
        }
    }

    /// Clear friend requests for a specific user (useful when user logs out or switches)
    func clearFriendRequestsForUser(_ userId: UUID) {
        friendRequests.removeValue(forKey: userId)
        saveToDisk()
    }
    
    // MARK: - Profile Methods
    
    func updateProfileStats(_ userId: UUID, _ stats: UserStatsDTO) {
        profileStats[userId] = stats
        lastChecked[CacheKeys.profileStats] = Date()
        saveToDisk()
    }
    
    func updateProfileInterests(_ userId: UUID, _ interests: [String]) {
        profileInterests[userId] = interests
        lastChecked[CacheKeys.profileInterests] = Date()
        saveToDisk()
    }
    
    func updateProfileSocialMedia(_ userId: UUID, _ socialMedia: UserSocialMediaDTO) {
        profileSocialMedia[userId] = socialMedia
        lastChecked[CacheKeys.profileSocialMedia] = Date()
        saveToDisk()
    }
    

    
    func updateProfileActivities(_ userId: UUID, _ activities: [ProfileActivityDTO]) {
        profileActivities[userId] = activities
        
        // Pre-assign colors for even distribution
        let activityIds = activities.map { $0.id }
        ActivityColorService.shared.assignColorsForActivities(activityIds)
        
        lastChecked[CacheKeys.profileEvents] = Date()
        saveToDisk()
    }
    
    // MARK: - Profile Picture Caching
    
    /// Preload profile pictures for a collection of users
    private func preloadProfilePictures<T: Nameable>(for users: [T]) async {
        let profilePictureCache = ProfilePictureCache.shared
        
        for user in users {
            guard let profilePictureUrl = user.profilePicture else { continue }
            
            // Only download if not already cached
            if profilePictureCache.getCachedImage(for: user.id) == nil {
                _ = await profilePictureCache.downloadAndCacheImage(from: profilePictureUrl, for: user.id)
            }
        }
    }
    
    /// Preload profile pictures for activity creators and participants
    private func preloadProfilePicturesForActivities(_ activities: [FullFeedActivityDTO]) async {
        let profilePictureCache = ProfilePictureCache.shared
        
        for activity in activities {
            // Preload creator profile picture
            if let creatorPicture = activity.creatorUser.profilePicture {
                if profilePictureCache.getCachedImage(for: activity.creatorUser.id) == nil {
                    _ = await profilePictureCache.downloadAndCacheImage(from: creatorPicture, for: activity.creatorUser.id)
                }
            }
            
            // Preload participant profile pictures
            if let participants = activity.participantUsers {
                for participant in participants {
                    if let participantPicture = participant.profilePicture {
                        if profilePictureCache.getCachedImage(for: participant.id) == nil {
                            _ = await profilePictureCache.downloadAndCacheImage(from: participantPicture, for: participant.id)
                        }
                    }
                }
            }
            
            // Preload invited user profile pictures
            if let invitedUsers = activity.invitedUsers {
                for invitedUser in invitedUsers {
                    if let invitedPicture = invitedUser.profilePicture {
                        if profilePictureCache.getCachedImage(for: invitedUser.id) == nil {
                            _ = await profilePictureCache.downloadAndCacheImage(from: invitedPicture, for: invitedUser.id)
                        }
                    }
                }
            }
            
            // Preload chat message senders' profile pictures
            if let chatMessages = activity.chatMessages {
                for chatMessage in chatMessages {
                    if let senderPicture = chatMessage.senderUser.profilePicture {
                        if profilePictureCache.getCachedImage(for: chatMessage.senderUser.id) == nil {
                            _ = await profilePictureCache.downloadAndCacheImage(from: senderPicture, for: chatMessage.senderUser.id)
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
                    if profilePictureCache.getCachedImage(for: request.senderUser.id) == nil {
                        _ = await profilePictureCache.downloadAndCacheImage(from: senderPicture, for: request.senderUser.id)
                    }
                }
            }
        }
    }
    
    func refreshProfileStats(_ userId: UUID) async {
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
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
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
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
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
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
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
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
        // Load cache timestamps
        if let timestampsData = UserDefaults.standard.data(forKey: CacheKeys.lastChecked),
           let loadedTimestamps = try? JSONDecoder().decode([String: Date].self, from: timestampsData) {
            lastChecked = loadedTimestamps
        }
        
        // Load friends
        if let friendsData = UserDefaults.standard.data(forKey: CacheKeys.friends),
           let loadedFriends = try? JSONDecoder().decode([FullFriendUserDTO].self, from: friendsData) {
            friends = loadedFriends
        }
        

        
        // Load activities
        if let activitiesData = UserDefaults.standard.data(forKey: CacheKeys.events),
           let loadedActivities = try? JSONDecoder().decode([FullFeedActivityDTO].self, from: activitiesData) {
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
           let loadedRecommended = try? JSONDecoder().decode([RecommendedFriendUserDTO].self, from: recommendedData) {
            recommendedFriends = loadedRecommended
        }
        
        // Load friend requests
        if let requestsData = UserDefaults.standard.data(forKey: CacheKeys.friendRequests),
           let loadedRequests = try? JSONDecoder().decode([UUID: [FetchFriendRequestDTO]].self, from: requestsData) {
            friendRequests = loadedRequests
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
        // Save cache timestamps
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
