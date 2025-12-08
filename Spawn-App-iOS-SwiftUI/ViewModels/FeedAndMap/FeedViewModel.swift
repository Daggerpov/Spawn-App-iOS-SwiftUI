//
//  FeedViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

@preconcurrency import Combine
import Foundation

@Observable
@MainActor
final class FeedViewModel {
	var activities: [FullFeedActivityDTO] = []

	// Use the ActivityTypeViewModel for managing activity types
	var activityTypeViewModel: ActivityTypeViewModel

	var userId: UUID
	private var dataService: DataService
	private var cancellables = Set<AnyCancellable>()

	// Throttle activities updates to prevent overwhelming MapView
	private var activitiesUpdateThrottle: AnyCancellable?
	private let activitiesSubject = PassthroughSubject<[FullFeedActivityDTO], Never>()

	/// Periodic refresh timer
	/// - Note: `nonisolated(unsafe)` allows safe access from nonisolated deinit.
	/// Thread safety is ensured by only accessing from MainActor context (via Timer's main runloop)
	/// and in deinit (which runs after all other accesses complete).
	@ObservationIgnored private nonisolated(unsafe) var refreshTimer: Timer?

	/// Periodic local cleanup timer for expired activities
	/// - Note: `nonisolated(unsafe)` allows safe access from nonisolated deinit.
	@ObservationIgnored private nonisolated(unsafe) var cleanupTimer: Timer?

	// MARK: - Computed Properties

	/// Returns activity types sorted with pinned ones first, then alphabetically
	/// Delegates to ActivityTypeViewModel which maintains the canonical activity types
	var sortedActivityTypes: [ActivityTypeDTO] {
		return activityTypeViewModel.sortedActivityTypes
	}

	init(userId: UUID) {
		self.userId = userId
		let dataServiceInstance = DataService.shared
		self.dataService = dataServiceInstance

		print("🔧 FeedViewModel.init() called for userId: \(userId)")
		// Initialize the activity type view model
		self.activityTypeViewModel = ActivityTypeViewModel(userId: userId, dataService: dataServiceInstance)

		// Throttle activities updates to prevent overwhelming MapView
		activitiesUpdateThrottle =
			activitiesSubject
			.throttle(for: .milliseconds(500), scheduler: DispatchQueue.main, latest: true)
			.sink { [weak self] newActivities in
				self?.activities = newActivities
			}

		// Register for activity creation notifications
		NotificationCenter.default.publisher(for: .activityCreated)
			.sink { [weak self] notification in
				guard let self = self else { return }

				// Optimistically add the newly created activity to the list immediately
				// This ensures instant UI feedback without waiting for API
				if let newActivity = notification.object as? FullFeedActivityDTO {
					Task { @MainActor in
						// Check if activity isn't already in the list (avoid duplicates)
						if !self.activities.contains(where: { $0.id == newActivity.id }) {
							// Prepend the new activity to show it at the top
							var updatedActivities = [newActivity] + self.activities
							// Filter expired activities just in case
							updatedActivities = self.filterExpiredActivities(updatedActivities)
							self.activitiesSubject.send(updatedActivities)
							print(
								"✅ FeedViewModel: Optimistically added new activity: \(newActivity.title ?? "Unknown")")
						}
					}
				}

				// Also refresh from API in background to ensure consistency
				Task {
					await self.forceRefreshActivities()
				}
			}
			.store(in: &cancellables)

		// Register for activity update notifications
		NotificationCenter.default.publisher(for: .activityUpdated)
			.sink { [weak self] notification in
				guard let self = self else { return }

				// Optimistically update the activity in the list immediately
				if let updatedActivity = notification.object as? FullFeedActivityDTO {
					Task { @MainActor in
						// Find and replace the activity in the list
						var currentActivities = self.activities
						if let index = currentActivities.firstIndex(where: { $0.id == updatedActivity.id }) {
							currentActivities[index] = updatedActivity
							self.activitiesSubject.send(currentActivities)
							print(
								"✅ FeedViewModel: Optimistically updated activity: \(updatedActivity.title ?? "Unknown")"
							)
						}
					}
				}

				// Also refresh from API in background to ensure consistency
				Task {
					await self.forceRefreshActivities()
				}
			}
			.store(in: &cancellables)

		// Register for activity deletion notifications
		NotificationCenter.default.publisher(for: .activityDeleted)
			.sink { [weak self] notification in
				guard let self = self else { return }

				// Optimistically remove the activity from the list immediately
				if let activityId = notification.object as? UUID {
					Task { @MainActor in
						let currentActivities = self.activities
						let filteredActivities = currentActivities.filter { $0.id != activityId }
						if filteredActivities.count < currentActivities.count {
							self.activitiesSubject.send(filteredActivities)
							print("✅ FeedViewModel: Optimistically removed deleted activity: \(activityId)")
						}
					}
				}

				// Also refresh from API in background to ensure consistency
				Task {
					await self.forceRefreshActivities()
				}
			}
			.store(in: &cancellables)

		// Register for activity refresh notifications
		NotificationCenter.default.publisher(for: .shouldRefreshActivities)
			.sink { [weak self] _ in
				Task {
					await self?.forceRefreshActivities()
				}
			}
			.store(in: &cancellables)

		// Start periodic refresh timer (every 2 minutes)
		startPeriodicRefresh()

		// Start periodic local cleanup timer (every 30 seconds)
		startPeriodicCleanup()
	}

	deinit {
		refreshTimer?.invalidate()
		refreshTimer = nil
		cleanupTimer?.invalidate()
		cleanupTimer = nil
	}

	// MARK: - Periodic Refresh

	private func startPeriodicRefresh() {
		stopPeriodicRefresh()  // Stop any existing timer

		refreshTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
			Task { [weak self] in
				await self?.refreshActivitiesInBackground()
			}
		}
	}

	private func stopPeriodicRefresh() {
		refreshTimer?.invalidate()
		refreshTimer = nil
	}

	private func refreshActivitiesInBackground() async {
		print("🔄 FeedViewModel: Performing periodic activity refresh")
		await fetchActivitiesFromAPI()
	}

	private func startPeriodicCleanup() {
		stopPeriodicCleanup()  // Stop any existing timer

		// Run cleanup every 30 seconds to remove expired activities locally
		cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
			guard self != nil else { return }

			// Class is @MainActor, so we must use MainActor.run to access properties from Timer callback
			Task { @MainActor [weak self] in
				guard let self = self else { return }
				let currentActivities = self.activities
				let filteredActivities = self.filterExpiredActivities(currentActivities)

				// Only update if activities were actually filtered out
				if filteredActivities.count < currentActivities.count {
					print(
						"🧹 FeedViewModel: Removed \(currentActivities.count - filteredActivities.count) expired activities from view"
					)
					self.activitiesSubject.send(filteredActivities)
				}
			}
		}
	}

	private func stopPeriodicCleanup() {
		cleanupTimer?.invalidate()
		cleanupTimer = nil
	}

	// MARK: - Public Timer Control

	/// Pause all periodic timers (useful when view is not visible)
	func pauseTimers() {
		print("⏸️ FeedViewModel: Pausing periodic timers")
		stopPeriodicRefresh()
		stopPeriodicCleanup()
	}

	/// Resume all periodic timers (useful when view becomes visible)
	func resumeTimers() {
		startPeriodicRefresh()
		startPeriodicCleanup()
	}

	/// Loads cached activities immediately from DataService cache
	/// Call this before fetchAllData() to show cached data instantly
	@MainActor
	func loadCachedActivities() {
		Task {
			// Use cache-only policy to get instant cache results
			let result: DataResult<[FullFeedActivityDTO]> = await dataService.read(
				.activities(userId: userId),
				cachePolicy: .cacheOnly
			)

			switch result {
			case .success(let cachedActivities, _):
				let filteredActivities = self.filterExpiredActivities(cachedActivities)
				self.activitiesSubject.send(filteredActivities)

			case .failure:
				print("⚠️ FeedViewModel: No cached activities available")
			}
		}
	}

	func fetchAllData(forceRefresh: Bool = false) async {
		// Fetch activities and activity types in parallel for faster loading
		if forceRefresh {
			// Force refresh from API using .apiOnly cache policy
			// DataService will still update the cache automatically after fetching
			async let activities: () = fetchActivitiesFromAPI()
			async let activityTypes: () = activityTypeViewModel.fetchActivityTypes(forceRefresh: true)

			// Wait for both to complete
			let _ = await (activities, activityTypes)
		} else {
			// Use cache-first strategy for normal navigation
			async let activities: () = fetchActivitiesForUser()
			async let activityTypes: () = activityTypeViewModel.fetchActivityTypes()

			// Wait for both to complete
			let _ = await (activities, activityTypes)
		}
	}

	func fetchActivitiesForUser() async {
		// Use DataService with cache-first policy and background refresh
		let result: DataResult<[FullFeedActivityDTO]> = await dataService.read(
			.activities(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let activities, _):
			let filteredActivities = self.filterExpiredActivities(activities)
			self.activitiesSubject.send(filteredActivities)

		case .failure(let error):
			APIError.logIfNotCancellation(error, message: "❌ FeedViewModel: Error fetching activities")
			self.activitiesSubject.send([])
		}
	}

	/// Force refresh activities from the API, bypassing cache
	func forceRefreshActivities() async {
		await fetchActivitiesFromAPI()
	}

	private func fetchActivitiesFromAPI() async {
		// Check if user is still authenticated before making API call
		guard UserAuthViewModel.shared.spawnUser != nil, UserAuthViewModel.shared.isLoggedIn else {
			print("Cannot fetch activities: User is not logged in")
			return
		}

		// Use .apiOnly cache policy to fetch fresh data from API
		// DataService will still update the cache automatically after fetching
		let result: DataResult<[FullFeedActivityDTO]> = await dataService.read(
			.activities(userId: userId),
			cachePolicy: .apiOnly
		)

		switch result {
		case .success(let activities, _):
			let filteredActivities = self.filterExpiredActivities(activities)
			self.activitiesSubject.send(filteredActivities)

		case .failure(let error):
			APIError.logIfNotCancellation(error, message: "❌ FeedViewModel: Error force refreshing activities")
			self.activitiesSubject.send([])
		}
	}

	/// Filters out expired activities based on server-side expiration status with client-side fallback.
	/// Primarily uses the backend's isExpired field, but also performs client-side validation
	/// as a fallback in case the backend cache has stale expiration data.
	private func filterExpiredActivities(_ activities: [FullFeedActivityDTO]) -> [FullFeedActivityDTO] {
		let now = Date()

		return activities.filter { activity in
			// First check: Use server-side expiration status if explicitly set to true
			if activity.isExpired == true {
				return false  // this bool means to filter it out
			}

			// Second check: Client-side validation as fallback for stale cache data
			// This ensures we filter out activities that should be expired even if backend cache is stale

			// If activity has an explicit end time, check if it has passed
			if let endTime = activity.endTime {
				if endTime < now {
					return false
				}
			} else {
				// For activities without end time, they expire at midnight (12 AM) of the following day
				// Use the client timezone if available, otherwise fall back to local timezone
				if let createdAt = activity.createdAt {
					let calendar = Calendar.current
					let timeZone: TimeZone

					if let clientTimezone = activity.clientTimezone,
						let tz = TimeZone(identifier: clientTimezone)
					{
						timeZone = tz
					} else {
						timeZone = .current
					}

					// Get the date the activity was created in the appropriate timezone
					var calendarWithTZ = calendar
					calendarWithTZ.timeZone = timeZone

					let createdDate = calendarWithTZ.startOfDay(for: createdAt)

					// Calculate midnight (12 AM) of the following day
					if let expirationTime = calendarWithTZ.date(byAdding: .day, value: 1, to: createdDate) {
						if now > expirationTime {
							return false
						}
					}
				}
			}

			// Activity is not expired -> don't filter
			return true
		}
	}
}
