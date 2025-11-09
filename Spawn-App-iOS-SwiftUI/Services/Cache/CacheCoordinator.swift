//
//  CacheCoordinator.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-11-07.
//

import Foundation
import Combine
import SwiftUI

/// Central coordinator for all cache services
/// Orchestrates cache validation, refresh operations, and cross-service coordination
class CacheCoordinator: ObservableObject {
    static let shared = CacheCoordinator()
    
    // MARK: - Cache Services
    let activityCache = ActivityCacheService.shared
    let friendshipCache = FriendshipCacheService.shared
    let profileCache = ProfileCacheService.shared
    let profilePictureCache = ProfilePictureCache.shared
    
    // MARK: - Constants
    private enum CacheKeys {
        static let friends = "friends"
        static let events = "events"
        static let activityTypes = "activityTypes"
        static let recommendedFriends = "recommendedFriends"
        static let friendRequests = "friendRequests"
        static let sentFriendRequests = "sentFriendRequests"
        static let otherProfiles = "otherProfiles"
        static let profileStats = "profileStats"
        static let profileInterests = "profileInterests"
        static let profileSocialMedia = "profileSocialMedia"
        static let profileEvents = "profileEvents"
    }
    
    // MARK: - Initialization
    private init() {
        // All cache services are initialized as singletons
    }
    
    // MARK: - Public Methods
    
    /// Initialize all cache services
    func initialize() {
        // Cache services initialize themselves on creation
        print("✅ [CACHE-COORDINATOR] All cache services initialized")
    }
    
    /// Clear all caches
    func clearAllCaches() {
        activityCache.clearAllCaches()
        friendshipCache.clearAllCaches()
        profileCache.clearAllCaches()
        profilePictureCache.clearAllCache()
        
        print("✅ [CACHE-COORDINATOR] All caches cleared successfully")
    }
    
    /// Clear all data for a specific user
    func clearAllDataForUser(_ userId: UUID) {
        activityCache.clearDataForUser(userId)
        friendshipCache.clearDataForUser(userId)
        profileCache.clearDataForUser(userId)
        profilePictureCache.removeCachedImage(for: userId)
        
        // Clear other profiles cache to prevent data leakage between users
        profileCache.otherProfiles.removeAll()
        
        // Clear notification preferences
        NotificationService.shared.clearPreferencesForUser(userId)
        
        print("💾 [CACHE-COORDINATOR] Cleared all cached data and preferences for user \(userId)")
    }
    
    /// Validate cache with backend and refresh stale items
    func validateCache() async {
        let startTime = Date()
        
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ [CACHE-COORDINATOR] Cannot validate cache: No logged in user")
            return
        }
        
        print("✅ [CACHE-COORDINATOR] Starting cache validation for user: \(userId)")
        
        // Double-check authentication state before proceeding
        guard UserAuthViewModel.shared.isLoggedIn else {
            print("❌ [CACHE-COORDINATOR] Cannot validate cache: User is not logged in")
            return
        }
        
        // Clear calendar caches due to data format changes
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            try await apiService.clearCalendarCaches()
        } catch {
            print("⚠️ Failed to clear calendar caches on startup: \(error.localizedDescription)")
        }
        
        // Collect timestamps from all cache services
        var allTimestamps: [String: Date] = [:]
        
        // Activity cache timestamps
        let activityTimestamps = activityCache.getLastCheckedForUser(userId)
        allTimestamps.merge(activityTimestamps) { _, new in new }
        
        // Friendship cache timestamps
        let friendshipTimestamps = friendshipCache.getLastCheckedForUser(userId)
        allTimestamps.merge(friendshipTimestamps) { _, new in new }
        
        // Profile cache timestamps
        let profileTimestamps = profileCache.getLastCheckedForUser(userId)
        allTimestamps.merge(profileTimestamps) { _, new in new }
        
        print("🔍 [CACHE-COORDINATOR] User cache timestamps: \(allTimestamps)")
        
        // If we have no cached items to validate for this user, request fresh data
        if allTimestamps.isEmpty {
            print("🔄 [CACHE-COORDINATOR] No cached items to validate, requesting fresh data for all cache types")
            
            async let friendsTask: () = friendshipCache.refreshFriends()
            async let activitiesTask: () = activityCache.refreshActivities()
            async let activityTypesTask: () = activityCache.refreshActivityTypes()
            async let recommendedFriendsTask: () = friendshipCache.refreshRecommendedFriends()
            async let friendRequestsTask: () = friendshipCache.refreshFriendRequests()
            async let sentFriendRequestsTask: () = friendshipCache.refreshSentFriendRequests()
            
            let _ = await (friendsTask, activitiesTask, activityTypesTask, recommendedFriendsTask, friendRequestsTask, sentFriendRequestsTask)
            
            // Clean up any expired activities after refresh
            activityCache.cleanupExpiredActivities()
            
            print("✅ [CACHE-COORDINATOR] Completed initial cache refresh for all cache types")
            return
        }
        
        // Validate cache with backend
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            let result = try await apiService.validateCache(allTimestamps)
            
            await MainActor.run {
                // Track which caches need refreshing
                var needsFriendsRefresh = false
                var needsActivitiesRefresh = false
                var needsActivityTypesRefresh = false
                var needsOtherProfilesRefresh = false
                var needsRecommendedFriendsRefresh = false
                var needsFriendRequestsRefresh = false
                var needsSentFriendRequestsRefresh = false
                
                // Process validation results for each cache type
                
                // Friends
                if let friendsResponse = result[CacheKeys.friends], friendsResponse.invalidate {
                    if let updatedItems = friendsResponse.updatedItems,
                       let updatedFriends = try? JSONDecoder().decode([UUID: [FullFriendUserDTO]].self, from: updatedItems) {
                        friendshipCache.updateFriends(updatedFriends)
                    } else {
                        needsFriendsRefresh = true
                    }
                }
                
                // Activities
                if let activitiesResponse = result[CacheKeys.events], activitiesResponse.invalidate {
                    if let updatedItems = activitiesResponse.updatedItems,
                       let updatedActivities = try? JSONDecoder().decode([UUID: [FullFeedActivityDTO]].self, from: updatedItems) {
                        // Filter expired activities before updating
                        var filteredUpdatedActivities: [UUID: [FullFeedActivityDTO]] = [:]
                        for (userId, userActivities) in updatedActivities {
                            filteredUpdatedActivities[userId] = userActivities.filter { activity in
                                return activity.isExpired != true
                            }
                        }
                        activityCache.updateActivities(filteredUpdatedActivities)
                    } else {
                        needsActivitiesRefresh = true
                    }
                }
                
                // Activity Types
                if let activityTypesResponse = result[CacheKeys.activityTypes], activityTypesResponse.invalidate {
                    if let updatedItems = activityTypesResponse.updatedItems,
                       let updatedActivityTypes = try? JSONDecoder().decode([ActivityTypeDTO].self, from: updatedItems) {
                        activityCache.updateActivityTypes(updatedActivityTypes)
                    } else {
                        needsActivityTypesRefresh = true
                    }
                }
                
                // Other Profiles
                if let otherProfilesResponse = result[CacheKeys.otherProfiles], otherProfilesResponse.invalidate {
                    needsOtherProfilesRefresh = true
                }
                
                // Recommended Friends
                if let recommendedFriendsResponse = result[CacheKeys.recommendedFriends], recommendedFriendsResponse.invalidate {
                    if let updatedItems = recommendedFriendsResponse.updatedItems,
                       let updatedRecommendedFriends = try? JSONDecoder().decode([UUID: [RecommendedFriendUserDTO]].self, from: updatedItems) {
                        friendshipCache.updateRecommendedFriends(updatedRecommendedFriends)
                    } else {
                        needsRecommendedFriendsRefresh = true
                    }
                }
                
                // Friend Requests
                if let friendRequestsResponse = result[CacheKeys.friendRequests], friendRequestsResponse.invalidate {
                    if let updatedItems = friendRequestsResponse.updatedItems,
                       let updatedFriendRequests = try? JSONDecoder().decode([UUID: [FetchFriendRequestDTO]].self, from: updatedItems) {
                        friendshipCache.updateFriendRequests(updatedFriendRequests)
                    } else {
                        needsFriendRequestsRefresh = true
                    }
                }
                
                // Sent Friend Requests
                if let sentFriendRequestsResponse = result[CacheKeys.sentFriendRequests], sentFriendRequestsResponse.invalidate {
                    if let updatedItems = sentFriendRequestsResponse.updatedItems,
                       let updatedSentFriendRequests = try? JSONDecoder().decode([UUID: [FetchSentFriendRequestDTO]].self, from: updatedItems) {
                        friendshipCache.updateSentFriendRequests(updatedSentFriendRequests)
                    } else {
                        needsSentFriendRequestsRefresh = true
                    }
                }
                
                // Perform refreshes if needed
                if needsFriendsRefresh || needsActivitiesRefresh || needsActivityTypesRefresh ||
                   needsOtherProfilesRefresh || needsRecommendedFriendsRefresh ||
                   needsFriendRequestsRefresh || needsSentFriendRequestsRefresh {

                    // Capture the current values to avoid Swift 6 concurrency warnings
                    let needsFriendsRefreshCapture = needsFriendsRefresh
                    let needsActivitiesRefreshCapture = needsActivitiesRefresh
                    let needsActivityTypesRefreshCapture = needsActivityTypesRefresh
                    let needsOtherProfilesRefreshCapture = needsOtherProfilesRefresh
                    let needsRecommendedFriendsRefreshCapture = needsRecommendedFriendsRefresh
                    let needsFriendRequestsRefreshCapture = needsFriendRequestsRefresh
                    let needsSentFriendRequestsRefreshCapture = needsSentFriendRequestsRefresh

                    Task {
                        async let friendsTask: () = needsFriendsRefreshCapture ? friendshipCache.refreshFriends() : noop()
                        async let activitiesTask: () = needsActivitiesRefreshCapture ? activityCache.refreshActivities() : noop()
                        async let activityTypesTask: () = needsActivityTypesRefreshCapture ? activityCache.refreshActivityTypes() : noop()
                        async let otherProfilesTask: () = needsOtherProfilesRefreshCapture ? profileCache.refreshOtherProfiles() : noop()
                        async let recommendedFriendsTask: () = needsRecommendedFriendsRefreshCapture ? friendshipCache.refreshRecommendedFriends() : noop()
                        async let friendRequestsTask: () = needsFriendRequestsRefreshCapture ? friendshipCache.refreshFriendRequests() : noop()
                        async let sentFriendRequestsTask: () = needsSentFriendRequestsRefreshCapture ? friendshipCache.refreshSentFriendRequests() : noop()

                        let _ = await (friendsTask, activitiesTask, activityTypesTask, otherProfilesTask, recommendedFriendsTask, friendRequestsTask, sentFriendRequestsTask)
                    }
                }
            }
            
        } catch {
            print("Failed to validate cache: \(error.localizedDescription)")
        }
        
        // After cache validation, refresh profile pictures for all cached users
        Task {
            await refreshAllProfilePictures()
        }
        
        let duration = Date().timeIntervalSince(startTime)
        print("⏱️ [CACHE-COORDINATOR] Cache validation completed in \(String(format: "%.2f", duration))s")
    }
    
    /// Force refresh all profile pictures
    func refreshAllProfilePictures() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ [CACHE-COORDINATOR] Cannot refresh profile pictures: No user ID available")
            return
        }
        
        print("🔄 [CACHE-COORDINATOR] Starting profile picture refresh for all cached users")
        
        var usersToRefresh: [(userId: UUID, profilePictureUrl: String?)] = []
        
        // Collect all users from different caches
        if let userFriends = friendshipCache.friends[userId] {
            for friend in userFriends {
                usersToRefresh.append((userId: friend.id, profilePictureUrl: friend.profilePicture))
            }
        }
        
        if let userRecommendedFriends = friendshipCache.recommendedFriends[userId] {
            for friend in userRecommendedFriends {
                usersToRefresh.append((userId: friend.id, profilePictureUrl: friend.profilePicture))
            }
        }
        
        if let userFriendRequests = friendshipCache.friendRequests[userId] {
            for request in userFriendRequests {
                usersToRefresh.append((userId: request.senderUser.id, profilePictureUrl: request.senderUser.profilePicture))
            }
        }
        
        if let userSentFriendRequests = friendshipCache.sentFriendRequests[userId] {
            for request in userSentFriendRequests {
                usersToRefresh.append((userId: request.receiverUser.id, profilePictureUrl: request.receiverUser.profilePicture))
            }
        }
        
        // Add other profiles
        for (_, profile) in profileCache.otherProfiles {
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
        
        print("✅ [CACHE-COORDINATOR] Completed profile picture refresh for all cached users")
    }
    
    /// Force refresh all profile pictures (public method)
    func forceRefreshAllProfilePictures() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            return
        }
        
        var usersToRefresh: [(userId: UUID, profilePictureUrl: String?)] = []
        
        // Collect all users from different caches
        if let userFriends = friendshipCache.friends[userId] {
            for friend in userFriends {
                usersToRefresh.append((userId: friend.id, profilePictureUrl: friend.profilePicture))
            }
        }
        
        if let userRecommendedFriends = friendshipCache.recommendedFriends[userId] {
            for friend in userRecommendedFriends {
                usersToRefresh.append((userId: friend.id, profilePictureUrl: friend.profilePicture))
            }
        }
        
        if let userFriendRequests = friendshipCache.friendRequests[userId] {
            for request in userFriendRequests {
                usersToRefresh.append((userId: request.senderUser.id, profilePictureUrl: request.senderUser.profilePicture))
            }
        }
        
        if let userSentFriendRequests = friendshipCache.sentFriendRequests[userId] {
            for request in userSentFriendRequests {
                usersToRefresh.append((userId: request.receiverUser.id, profilePictureUrl: request.receiverUser.profilePicture))
            }
        }
        
        // Add other profiles
        for (_, profile) in profileCache.otherProfiles {
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
        
        // Force refresh all profile pictures
        for user in uniqueUsers {
            guard let profilePictureUrl = user.profilePictureUrl else { continue }
            _ = await profilePictureCache.refreshProfilePicture(for: user.userId, from: profilePictureUrl)
        }
    }
    
    /// Diagnostic method to force refresh all data with detailed logging
    func diagnosticForceRefresh() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("❌ [DIAGNOSTIC] Cannot run diagnostic: No user ID available")
            return
        }
        
        print("🔍 [DIAGNOSTIC] Starting diagnostic refresh for user: \(userId)")
        
        // Run diagnostics on all cache services
        await friendshipCache.diagnosticForceRefresh()
        await activityCache.forceRefreshAll()
        await profileCache.forceRefreshAll()
        
        print("✅ [DIAGNOSTIC] Diagnostic refresh completed")
    }
    
    // MARK: - Helper Methods
    
    /// No-op async function for conditional parallel execution
    private func noop() async {
        // Does nothing - used for conditional async let statements
    }
}

