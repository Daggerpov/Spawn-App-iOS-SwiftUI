//
//  FeedViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation
import Combine

class FeedViewModel: ObservableObject {
    @Published var activities: [FullFeedActivityDTO] = []
    @Published var activityTypes: [ActivityTypeDTO] = []
    
    // Use the ActivityTypeViewModel for managing activity types
    @Published var activityTypeViewModel: ActivityTypeViewModel

    var apiService: IAPIService
    var userId: UUID
    private var appCache: AppCache
    private var cancellables = Set<AnyCancellable>()
    
    // Periodic refresh timer
    private var refreshTimer: Timer?

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

    init(apiService: IAPIService, userId: UUID) {
        self.apiService = apiService
        self.userId = userId
        self.appCache = AppCache.shared
        
        // Initialize the activity type view model
        self.activityTypeViewModel = ActivityTypeViewModel(userId: userId, apiService: apiService)
        
        // Subscribe to activity type changes to update the UI
        activityTypeViewModel.$activityTypes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newActivityTypes in
                self?.activityTypes = newActivityTypes
            }
            .store(in: &cancellables)
        
        // Only subscribe to AppCache if not mocking
        if !MockAPIService.isMocking {
            // Subscribe to AppCache activities updates
            appCache.$activities
                .receive(on: DispatchQueue.main)
                .sink { [weak self] cachedActivities in
                    guard let self = self else { return }
                    let userActivities = cachedActivities[self.userId] ?? []
                    if !userActivities.isEmpty {
                        self.activities = self.filterExpiredActivities(userActivities)
                    }
                }
                .store(in: &cancellables)
        }
            
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
                // Force immediate UI refresh by updating activity types from the cache
                if let self = self {
                    Task { @MainActor in
                        self.activityTypes = self.appCache.activityTypes
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
    }
    
    deinit {
        stopPeriodicRefresh()
    }
    
    // MARK: - Periodic Refresh
    
    private func startPeriodicRefresh() {
        stopPeriodicRefresh() // Stop any existing timer
        
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

    func fetchAllData() async {
        await fetchActivitiesForUser()
        await activityTypeViewModel.fetchActivityTypes()
    }

    func fetchActivitiesForUser() async {
        // Check the cache first for current user's activities
        let currentUserActivities = appCache.getCurrentUserActivities()
        if !currentUserActivities.isEmpty {
            await MainActor.run {
                self.activities = self.filterExpiredActivities(currentUserActivities)
            }
            // Still fetch from API in background to ensure freshness
            Task {
                await fetchActivitiesFromAPI()
            }
            return
        }
        
        // If not in cache, fetch from API
        await fetchActivitiesFromAPI()
    }
    
    /// Force refresh activities from the API, bypassing cache
    func forceRefreshActivities() async {
        print("🔄 FeedViewModel: Force refreshing activities")
        await fetchActivitiesFromAPI()
    }
    

    
    private func fetchActivitiesFromAPI() async {
        // Check if user is still authenticated before making API call
        guard UserAuthViewModel.shared.spawnUser != nil, UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot fetch activities: User is not logged in")
            return
        }
        
        // Path: /api/v1/activities/feedActivities/{requestingUserId}
        guard let url = URL(string: APIService.baseURL + "activities/feedActivities/\(userId)") else {
            print("❌ DEBUG: Failed to construct URL for activities")
            return
        }

        do {
            let fetchedActivities: [FullFeedActivityDTO] = try await self.apiService.fetchData(
                from: url, parameters: nil
            )
            
            // Filter expired activities and update the cache and view model
            let filteredActivities = self.filterExpiredActivities(fetchedActivities)
            await MainActor.run {
                self.activities = filteredActivities
                self.appCache.updateActivitiesForUser(fetchedActivities, userId: self.userId) // Cache will filter expired activities internally
            }
        } catch {
            print("❌ DEBUG: Error fetching activities: \(error)")
            await MainActor.run {
                self.activities = []
            }
        }
    }
    
    /// Filters out expired activities based on server-side expiration status.
    /// This method now relies on the back-end's isExpired field as the single source of truth
    /// for consistent expiration logic across all clients.
    private func filterExpiredActivities(_ activities: [FullFeedActivityDTO]) -> [FullFeedActivityDTO] {
        return activities.filter { activity in
            // Use server-side expiration status as single source of truth
            return activity.isExpired != true
        }
    }
}
