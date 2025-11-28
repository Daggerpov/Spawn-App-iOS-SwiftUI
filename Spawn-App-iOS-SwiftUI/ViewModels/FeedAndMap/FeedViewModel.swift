//
//  FeedViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Combine
import Foundation

class FeedViewModel: ObservableObject {
	@Published var activities: [FullFeedActivityDTO] = []
	@Published var activityTypes: [ActivityTypeDTO] = []

	// Use the ActivityTypeViewModel for managing activity types
	@Published var activityTypeViewModel: ActivityTypeViewModel

	var userId: UUID
	private var dataService: DataService
	private var cancellables = Set<AnyCancellable>()

	// Throttle activities updates to prevent overwhelming MapView
	private var activitiesUpdateThrottle: AnyCancellable?
	private let activitiesSubject = PassthroughSubject<[FullFeedActivityDTO], Never>()

	// Periodic refresh timer
	private var refreshTimer: Timer?

	// Periodic local cleanup timer for expired activities
	private var cleanupTimer: Timer?

	// MARK: - Computed Properties

	/// Returns activity types sorted with pinned ones first, then alphabetically
	var sortedActivityTypes: [ActivityTypeDTO] {
		return activityTypes.sorted { first, second in
			// Pinned types come first
			if first.isPinned != second.isPinned {
				return first.isPinned
			}
			// If both are pinned or both are not pinned, sort alphabetically by title
			return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
		}
	}

	init(userId: UUID) {
		self.userId = userId
		self.dataService = DataService.shared

		// Initialize the activity type view model
		self.activityTypeViewModel = ActivityTypeViewModel(userId: userId, dataService: dataService)

		// Throttle activities updates to prevent overwhelming MapView
		activitiesUpdateThrottle =
			activitiesSubject
			.throttle(for: .milliseconds(500), scheduler: DispatchQueue.main, latest: true)
			.sink { [weak self] newActivities in
				self?.activities = newActivities
			}

		// Subscribe to activity type changes to update the UI
		activityTypeViewModel.$activityTypes
			.receive(on: DispatchQueue.main)
			.sink { [weak self] newActivityTypes in
				self?.activityTypes = newActivityTypes
			}
			.store(in: &cancellables)

		// Register for activity creation notifications
		NotificationCenter.default.publisher(for: .activityCreated)
			.sink { [weak self] _ in
				Task {
					await self?.fetchActivitiesForUser()
				}
			}
			.store(in: &cancellables)

		// Register for activity update notifications
		NotificationCenter.default.publisher(for: .activityUpdated)
			.sink { [weak self] _ in
				Task {
					await self?.fetchActivitiesForUser()
				}
			}
			.store(in: &cancellables)

		// Register for activity deletion notifications
		NotificationCenter.default.publisher(for: .activityDeleted)
			.sink { [weak self] notification in
				Task {
					await self?.fetchActivitiesForUser()
				}
			}
			.store(in: &cancellables)

		// Register for activity type changes for immediate UI refresh
		NotificationCenter.default.publisher(for: .activityTypesChanged)
			.sink { [weak self] _ in
				// Force immediate UI refresh by updating activity types from the view model
				if let self = self {
					Task { @MainActor in
						self.activityTypes = self.activityTypeViewModel.activityTypes
						self.objectWillChange.send()
					}
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
		stopPeriodicRefresh()
		stopPeriodicCleanup()
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
			guard let self = self else { return }

			Task { @MainActor [weak self] in
				guard let self = self else { return }
				let filteredActivities = self.filterExpiredActivities(self.activities)

				// Only update if activities were actually filtered out
				if filteredActivities.count < self.activities.count {
					print(
						"🧹 FeedViewModel: Removed \(self.activities.count - filteredActivities.count) expired activities from view"
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

	func fetchAllData() async {
		// Fetch activities and activity types in parallel for faster loading
		async let activities: () = fetchActivitiesForUser()
		async let activityTypes: () = activityTypeViewModel.fetchActivityTypes()

		// Wait for both to complete
		let _ = await (activities, activityTypes)
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
			await MainActor.run {
				self.activitiesSubject.send(filteredActivities)
			}

		case .failure(let error):
			APIError.logIfNotCancellation(error, message: "❌ FeedViewModel: Error fetching activities")
			await MainActor.run {
				self.activitiesSubject.send([])
			}
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

		// Use DataService with API-only policy to force refresh
		let result: DataResult<[FullFeedActivityDTO]> = await dataService.read(
			.activities(userId: userId),
			cachePolicy: .apiOnly
		)

		switch result {
		case .success(let activities, _):
			let filteredActivities = self.filterExpiredActivities(activities)
			await MainActor.run {
				self.activitiesSubject.send(filteredActivities)
			}

		case .failure(let error):
			APIError.logIfNotCancellation(error, message: "❌ FeedViewModel: Error force refreshing activities")
			await MainActor.run {
				self.activitiesSubject.send([])
			}
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
