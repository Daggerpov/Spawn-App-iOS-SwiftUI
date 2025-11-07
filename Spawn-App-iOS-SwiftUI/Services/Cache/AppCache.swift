//
//  AppCache.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-04-20.
//  Refactored by Daniel Agapov on 2025-11-07.
//
//  NOTE: This class now serves as a facade/wrapper around domain-specific cache services.
//  All actual caching logic is handled by:
//  - ActivityCacheService (activities, activityTypes)
//  - FriendshipCacheService (friends, recommendedFriends, friendRequests, sentFriendRequests)
//  - ProfileCacheService (otherProfiles, profileStats, profileInterests, profileSocialMedia, profileActivities)
//  - ProfilePictureCache (profile pictures)
//

import Foundation
import SwiftUI
import Combine

/// A singleton cache manager that stores app data locally and checks for invalidation on app launch
/// This class maintains backward compatibility by delegating to domain-specific cache services
class AppCache: ObservableObject {
    static let shared = AppCache()
    
    // MARK: - Cache Services
    private let coordinator = CacheCoordinator.shared
    private let activityCacheService = ActivityCacheService.shared
    private let friendshipCacheService = FriendshipCacheService.shared
    private let profileCacheService = ProfileCacheService.shared
    
    // MARK: - Cancellables for syncing
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties (Synced with underlying cache services)
    
    // Activity-related data
    @Published var activities: [UUID: [FullFeedActivityDTO]] = [:]
    @Published var activityTypes: [ActivityTypeDTO] = []
    
    // Friendship-related data
    @Published var friends: [UUID: [FullFriendUserDTO]] = [:]
    @Published var recommendedFriends: [UUID: [RecommendedFriendUserDTO]] = [:]
    @Published var friendRequests: [UUID: [FetchFriendRequestDTO]] = [:]
    @Published var sentFriendRequests: [UUID: [FetchSentFriendRequestDTO]] = [:]
    
    // Profile-related data
    @Published var otherProfiles: [UUID: BaseUserDTO] = [:]
    @Published var profileStats: [UUID: UserStatsDTO] = [:]
    @Published var profileInterests: [UUID: [String]] = [:]
    @Published var profileSocialMedia: [UUID: UserSocialMediaDTO] = [:]
    @Published var profileActivities: [UUID: [ProfileActivityDTO]] = [:]
    
    // MARK: - Initialization
    
    private init() {
        // Cache services initialize themselves
        coordinator.initialize()
        
        // Set up two-way sync between AppCache and cache services
        setupSyncWithCacheServices()
    }
    
    /// Set up bidirectional sync between AppCache @Published properties and cache service @Published properties
    private func setupSyncWithCacheServices() {
        // Sync from cache services to AppCache (one-way for now to avoid loops)
        activityCacheService.$activities
            .assign(to: \.activities, on: self)
            .store(in: &cancellables)
        
        activityCacheService.$activityTypes
            .assign(to: \.activityTypes, on: self)
            .store(in: &cancellables)
        
        friendshipCacheService.$friends
            .assign(to: \.friends, on: self)
            .store(in: &cancellables)
        
        friendshipCacheService.$recommendedFriends
            .assign(to: \.recommendedFriends, on: self)
            .store(in: &cancellables)
        
        friendshipCacheService.$friendRequests
            .assign(to: \.friendRequests, on: self)
            .store(in: &cancellables)
        
        friendshipCacheService.$sentFriendRequests
            .assign(to: \.sentFriendRequests, on: self)
            .store(in: &cancellables)
        
        profileCacheService.$otherProfiles
            .assign(to: \.otherProfiles, on: self)
            .store(in: &cancellables)
        
        profileCacheService.$profileStats
            .assign(to: \.profileStats, on: self)
            .store(in: &cancellables)
        
        profileCacheService.$profileInterests
            .assign(to: \.profileInterests, on: self)
            .store(in: &cancellables)
        
        profileCacheService.$profileSocialMedia
            .assign(to: \.profileSocialMedia, on: self)
            .store(in: &cancellables)
        
        profileCacheService.$profileActivities
            .assign(to: \.profileActivities, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Initialize the cache and load from disk in the background
    func initialize() {
        coordinator.initialize()
    }
    
    /// Clear all cached data and reset the cache state
    func clearAllCaches() {
        coordinator.clearAllCaches()
    }
    
    /// Validate cache with backend and refresh stale items
    func validateCache() async {
        await coordinator.validateCache()
    }
    
    // MARK: - Friends Methods
    
    func updateFriends(_ newFriends: [UUID: [FullFriendUserDTO]]) {
        friendshipCacheService.updateFriends(newFriends)
    }
    
    func refreshFriends() async {
        await friendshipCacheService.refreshFriends()
    }
    
    // MARK: - Activities Methods
    
    func updateActivities(_ newActivities: [UUID: [FullFeedActivityDTO]]) {
        activityCacheService.updateActivities(newActivities)
    }
    
    func refreshActivities() async {
        await activityCacheService.refreshActivities()
    }
    
    func getActivityById(_ activityId: UUID) -> FullFeedActivityDTO? {
        return activityCacheService.getActivityById(activityId)
    }
    
    func addOrUpdateActivity(_ activity: FullFeedActivityDTO) {
        activityCacheService.addOrUpdateActivity(activity)
    }
    
    func removeActivity(_ activityId: UUID) {
        activityCacheService.removeActivity(activityId)
    }
    
    func optimisticallyUpdateActivity(_ activity: FullFeedActivityDTO) {
        activityCacheService.optimisticallyUpdateActivity(activity)
    }
    
    // MARK: - Activity Types Methods
    
    func updateActivityTypes(_ newActivityTypes: [ActivityTypeDTO]) {
        activityCacheService.updateActivityTypes(newActivityTypes)
    }
    
    func refreshActivityTypes() async {
        await activityCacheService.refreshActivityTypes()
    }
    
    func getActivityTypesForUser(_ userId: UUID) -> [ActivityTypeDTO] {
        return activityCacheService.getActivityTypesForUser(userId)
    }
    
    func addOrUpdateActivityTypes(_ newActivityTypes: [ActivityTypeDTO]) {
        activityCacheService.addOrUpdateActivityTypes(newActivityTypes)
    }
    
    func updateActivityTypeInCache(_ activityTypeDTO: ActivityTypeDTO) {
        activityCacheService.updateActivityTypeInCache(activityTypeDTO)
    }
    
    // MARK: - Other Profiles Methods
    
    func updateOtherProfile(_ userId: UUID, _ profile: BaseUserDTO) {
        profileCacheService.updateOtherProfile(userId, profile)
    }
    
    func refreshOtherProfiles() async {
        await profileCacheService.refreshOtherProfiles()
    }
    
    // MARK: - Recommended Friends Methods
    
    func updateRecommendedFriends(_ newRecommendedFriends: [UUID: [RecommendedFriendUserDTO]]) {
        friendshipCacheService.updateRecommendedFriends(newRecommendedFriends)
    }
    
    func refreshRecommendedFriends() async {
        await friendshipCacheService.refreshRecommendedFriends()
    }
    
    // MARK: - Friend Requests Methods
    
    func getCurrentUserFriendRequests() -> [FetchFriendRequestDTO] {
        return friendshipCacheService.getCurrentUserFriendRequests()
    }
    
    func updateFriendRequestsForUser(_ newFriendRequests: [FetchFriendRequestDTO], userId: UUID) {
        friendshipCacheService.updateFriendRequestsForUser(newFriendRequests, userId: userId)
    }
    
    func updateFriendRequests(_ newFriendRequests: [UUID: [FetchFriendRequestDTO]]) {
        friendshipCacheService.updateFriendRequests(newFriendRequests)
    }
    
    func refreshFriendRequests() async {
        await friendshipCacheService.refreshFriendRequests()
    }
    
    func clearFriendRequestsForUser(_ userId: UUID) {
        friendshipCacheService.clearFriendRequestsForUser(userId)
    }
    
    // MARK: - Sent Friend Requests Methods
    
    func getCurrentUserSentFriendRequests() -> [FetchSentFriendRequestDTO] {
        return friendshipCacheService.getCurrentUserSentFriendRequests()
    }
    
    func updateSentFriendRequestsForUser(_ newSentFriendRequests: [FetchSentFriendRequestDTO], userId: UUID) {
        friendshipCacheService.updateSentFriendRequestsForUser(newSentFriendRequests, userId: userId)
    }
    
    func updateSentFriendRequests(_ newSentFriendRequests: [UUID: [FetchSentFriendRequestDTO]]) {
        friendshipCacheService.updateSentFriendRequests(newSentFriendRequests)
    }
    
    func refreshSentFriendRequests() async {
        await friendshipCacheService.refreshSentFriendRequests()
    }
    
    func clearSentFriendRequestsForUser(_ userId: UUID) {
        friendshipCacheService.clearSentFriendRequestsForUser(userId)
    }
    
    func forceRefreshAllFriendRequests() async {
        await friendshipCacheService.forceRefreshAllFriendRequests()
    }
    
    // MARK: - User-Specific Data Helper Methods
    
    func getCurrentUserFriends() -> [FullFriendUserDTO] {
        return friendshipCacheService.getCurrentUserFriends()
    }
    
    func updateFriendsForUser(_ newFriends: [FullFriendUserDTO], userId: UUID) {
        friendshipCacheService.updateFriendsForUser(newFriends, userId: userId)
    }
    
    func clearFriendsForUser(_ userId: UUID) {
        friendshipCacheService.clearFriendsForUser(userId)
    }
    
    func getCurrentUserActivities() -> [FullFeedActivityDTO] {
        return activityCacheService.getCurrentUserActivities()
    }
    
    func updateActivitiesForUser(_ newActivities: [FullFeedActivityDTO], userId: UUID) {
        activityCacheService.updateActivitiesForUser(newActivities, userId: userId)
    }
    
    func clearActivitiesForUser(_ userId: UUID) {
        activityCacheService.clearActivitiesForUser(userId)
    }
    
    func cleanupExpiredActivities() {
        activityCacheService.cleanupExpiredActivities()
    }
    
    func getCurrentUserRecommendedFriends() -> [RecommendedFriendUserDTO] {
        return friendshipCacheService.getCurrentUserRecommendedFriends()
    }
    
    func updateRecommendedFriendsForUser(_ newRecommendedFriends: [RecommendedFriendUserDTO], userId: UUID) {
        friendshipCacheService.updateRecommendedFriendsForUser(newRecommendedFriends, userId: userId)
    }
    
    func clearRecommendedFriendsForUser(_ userId: UUID) {
        friendshipCacheService.clearRecommendedFriendsForUser(userId)
    }
    
    func clearAllDataForUser(_ userId: UUID) {
        coordinator.clearAllDataForUser(userId)
    }
    
    // MARK: - Profile Methods
    
    func updateProfileStats(_ userId: UUID, _ stats: UserStatsDTO) {
        profileCacheService.updateProfileStats(userId, stats)
    }
    
    func updateProfileInterests(_ userId: UUID, _ interests: [String]) {
        profileCacheService.updateProfileInterests(userId, interests)
    }
    
    func updateProfileSocialMedia(_ userId: UUID, _ socialMedia: UserSocialMediaDTO) {
        profileCacheService.updateProfileSocialMedia(userId, socialMedia)
    }
    
    func updateProfileActivities(_ userId: UUID, _ activities: [ProfileActivityDTO]) {
        profileCacheService.updateProfileActivities(userId, activities)
    }
    
    func refreshProfileStats(_ userId: UUID) async {
        await profileCacheService.refreshProfileStats(userId)
    }
    
    func refreshProfileInterests(_ userId: UUID) async {
        await profileCacheService.refreshProfileInterests(userId)
    }
    
    func refreshProfileSocialMedia(_ userId: UUID) async {
        await profileCacheService.refreshProfileSocialMedia(userId)
    }
    
    func refreshProfileActivities(_ userId: UUID) async {
        await profileCacheService.refreshProfileActivities(userId)
    }
    
    // MARK: - Profile Picture Methods
    
    func refreshAllProfilePictures() async {
        await coordinator.refreshAllProfilePictures()
    }
    
    func forceRefreshAllProfilePictures() async {
        await coordinator.forceRefreshAllProfilePictures()
    }
    
    // MARK: - Diagnostic Methods
    
    func diagnosticForceRefresh() async {
        await coordinator.diagnosticForceRefresh()
    }
}
