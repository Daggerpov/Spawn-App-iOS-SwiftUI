//
//  AppCache.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-04-20.
//  Refactored by Daniel Agapov on 2025-11-07.
//
//  Pure facade/wrapper around the CacheCoordinator and domain-specific cache services.
//  This class provides a convenient interface for accessing cache functionality without
//  maintaining duplicate state. All data is stored and published by the domain services:
//  - ActivityCacheService (activities, activityTypes)
//  - FriendshipCacheService (friends, recommendedFriends, friendRequests, sentFriendRequests)
//  - ProfileCacheService (otherProfiles, profileStats, profileInterests, profileSocialMedia, profileActivities)
//  - ProfilePictureCache (profile pictures)
//

import Foundation
import SwiftUI

/// A singleton cache manager facade that provides convenient access to all cache services
/// Conforms to ObservableObject for SwiftUI compatibility, but all reactive state is managed by the underlying cache services
@MainActor
final class AppCache: ObservableObject {
	static let shared = AppCache()

	// MARK: - Cache Services
	private let coordinator = CacheCoordinator.shared
	private let activityCacheService = ActivityCacheService.shared
	private let friendshipCacheService = FriendshipCacheService.shared
	private let profileCacheService = ProfileCacheService.shared

	// MARK: - Initialization

	private init() {
		// Cache services initialize themselves
		coordinator.initialize()
	}

	// MARK: - Published Properties (Exposed from underlying services)

	// Activity-related data - exposed from ActivityCacheService
	var activities: [UUID: [FullFeedActivityDTO]] {
		activityCacheService.activities
	}

	var activityTypes: [UUID: [ActivityTypeDTO]] {
		activityCacheService.activityTypes
	}

	// Expose publishers for SwiftUI subscriptions
	var activitiesPublisher: Published<[UUID: [FullFeedActivityDTO]]>.Publisher {
		activityCacheService.$activities
	}

	var activityTypesPublisher: Published<[UUID: [ActivityTypeDTO]]>.Publisher {
		activityCacheService.$activityTypes
	}

	// Friendship-related data - exposed from FriendshipCacheService
	var friends: [UUID: [FullFriendUserDTO]] {
		friendshipCacheService.friends
	}

	var recommendedFriends: [UUID: [RecommendedFriendUserDTO]] {
		friendshipCacheService.recommendedFriends
	}

	var friendRequests: [UUID: [FetchFriendRequestDTO]] {
		friendshipCacheService.friendRequests
	}

	var sentFriendRequests: [UUID: [FetchSentFriendRequestDTO]] {
		friendshipCacheService.sentFriendRequests
	}

	// Expose publishers for SwiftUI subscriptions
	var friendsPublisher: Published<[UUID: [FullFriendUserDTO]]>.Publisher {
		friendshipCacheService.$friends
	}

	var recommendedFriendsPublisher: Published<[UUID: [RecommendedFriendUserDTO]]>.Publisher {
		friendshipCacheService.$recommendedFriends
	}

	var friendRequestsPublisher: Published<[UUID: [FetchFriendRequestDTO]]>.Publisher {
		friendshipCacheService.$friendRequests
	}

	var sentFriendRequestsPublisher: Published<[UUID: [FetchSentFriendRequestDTO]]>.Publisher {
		friendshipCacheService.$sentFriendRequests
	}

	// Profile-related data
	var otherProfiles: [UUID: BaseUserDTO] {
		profileCacheService.otherProfiles
	}

	var profileStats: [UUID: UserStatsDTO] {
		profileCacheService.profileStats
	}

	var profileInterests: [UUID: [String]] {
		profileCacheService.profileInterests
	}

	var profileSocialMedia: [UUID: UserSocialMediaDTO] {
		profileCacheService.profileSocialMedia
	}

	var profileActivities: [UUID: [ProfileActivityDTO]] {
		profileCacheService.profileActivities
	}

	var notificationPreferences: [UUID: NotificationPreferencesDTO] {
		profileCacheService.notificationPreferences
	}

	var blockedUsers: [UUID: [BlockedUserDTO]] {
		profileCacheService.blockedUsers
	}

	// Upcoming activities - exposed from ActivityCacheService
	var upcomingActivities: [UUID: [FullFeedActivityDTO]] {
		activityCacheService.upcomingActivities
	}

	// Calendar activities - exposed from ActivityCacheService
	var calendarActivities: [String: [CalendarActivityDTO]] {
		activityCacheService.calendarActivities
	}

	// Recently spawned with - exposed from FriendshipCacheService
	var recentlySpawnedWith: [UUID: [RecentlySpawnedUserDTO]] {
		friendshipCacheService.recentlySpawnedWith
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

	/// Get activity types for the current user
	func getCurrentUserActivityTypes() -> [ActivityTypeDTO] {
		return activityCacheService.getCurrentUserActivityTypes()
	}

	/// Update activity types for a specific user
	func updateActivityTypesForUser(_ newActivityTypes: [ActivityTypeDTO], userId: UUID) {
		activityCacheService.updateActivityTypesForUser(newActivityTypes, userId: userId)
	}

	/// Update activity types (for all users - used by cache validation)
	func updateActivityTypes(_ newActivityTypes: [UUID: [ActivityTypeDTO]]) {
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

	func clearActivityTypesForUser(_ userId: UUID) {
		activityCacheService.clearActivityTypesForUser(userId)
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

	// MARK: - Notification Preferences Methods

	func getNotificationPreferences(for userId: UUID) -> NotificationPreferencesDTO? {
		return profileCacheService.getNotificationPreferences(for: userId)
	}

	func updateNotificationPreferences(_ userId: UUID, _ preferences: NotificationPreferencesDTO) {
		profileCacheService.updateNotificationPreferences(userId, preferences)
	}

	func refreshNotificationPreferences(_ userId: UUID) async {
		await profileCacheService.refreshNotificationPreferences(userId)
	}

	// MARK: - Blocked Users Methods

	func getBlockedUsers(for userId: UUID) -> [BlockedUserDTO]? {
		return profileCacheService.getBlockedUsers(for: userId)
	}

	func updateBlockedUsers(_ userId: UUID, _ users: [BlockedUserDTO]) {
		profileCacheService.updateBlockedUsers(userId, users)
	}

	func refreshBlockedUsers(_ userId: UUID) async {
		await profileCacheService.refreshBlockedUsers(userId)
	}

	// MARK: - Upcoming Activities Methods

	func getUpcomingActivities(for userId: UUID) -> [FullFeedActivityDTO] {
		return activityCacheService.getUpcomingActivities(for: userId)
	}

	func updateUpcomingActivitiesForUser(_ activities: [FullFeedActivityDTO], userId: UUID) {
		activityCacheService.updateUpcomingActivitiesForUser(activities, userId: userId)
	}

	func refreshUpcomingActivities() async {
		await activityCacheService.refreshUpcomingActivities()
	}

	// MARK: - Calendar Activities Methods

	func getCalendarActivities(for userId: UUID, month: Int, year: Int) -> [CalendarActivityDTO]? {
		return activityCacheService.getCalendarActivities(for: userId, month: month, year: year)
	}

	func getAllCalendarActivities(for userId: UUID) -> [CalendarActivityDTO]? {
		return activityCacheService.getAllCalendarActivities(for: userId)
	}

	func updateCalendarActivitiesForMonth(_ activities: [CalendarActivityDTO], userId: UUID, month: Int, year: Int) {
		activityCacheService.updateCalendarActivitiesForMonth(activities, userId: userId, month: month, year: year)
	}

	func updateAllCalendarActivities(_ activities: [CalendarActivityDTO], userId: UUID) {
		activityCacheService.updateAllCalendarActivities(activities, userId: userId)
	}

	func refreshCalendarActivities(userId: UUID, month: Int, year: Int, requestingUserId: UUID?) async {
		await activityCacheService.refreshCalendarActivities(
			userId: userId, month: month, year: year, requestingUserId: requestingUserId
		)
	}

	func refreshAllCalendarActivities(userId: UUID, requestingUserId: UUID?) async {
		await activityCacheService.refreshAllCalendarActivities(userId: userId, requestingUserId: requestingUserId)
	}

	// MARK: - Recently Spawned With Methods

	func getRecentlySpawnedWith(for userId: UUID) -> [RecentlySpawnedUserDTO] {
		return friendshipCacheService.getRecentlySpawnedWith(for: userId)
	}

	func updateRecentlySpawnedWithForUser(_ users: [RecentlySpawnedUserDTO], userId: UUID) {
		friendshipCacheService.updateRecentlySpawnedWithForUser(users, userId: userId)
	}

	func refreshRecentlySpawnedWith() async {
		await friendshipCacheService.refreshRecentlySpawnedWith()
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
