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

    // MARK: - Computed Properties
    
    /// Returns activity types sorted with pinned ones first, then by orderNum
    var sortedActivityTypes: [ActivityTypeDTO] {
        return activityTypes.sorted { first, second in
            // Pinned types come first
            if first.isPinned != second.isPinned {
                return first.isPinned
            }
            // If both are pinned or both are not pinned, sort by orderNum
            return first.orderNum < second.orderNum
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
                        self.activities = self.filterExpiredIndefiniteActivities(userActivities)
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
                self.activities = self.filterExpiredIndefiniteActivities(currentUserActivities)
            }
            return
        }
        
        // If not in cache, fetch from API
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
            
            // Filter expired indefinite activities and update the cache and view model
            let filteredActivities = self.filterExpiredIndefiniteActivities(fetchedActivities)
            await MainActor.run {
                self.activities = filteredActivities
                self.appCache.updateActivitiesForUser(fetchedActivities, userId: self.userId) // Keep original activities in cache
            }
        } catch {
            print("❌ DEBUG: Error fetching activities: \(error)")
            await MainActor.run {
                self.activities = []
            }
        }
    }
    
    /// Filters out indefinite activities (null end time) that have a start time before the current client-side day
    /// Indefinite activities 'expire' by midnight of the local time
    private func filterExpiredIndefiniteActivities(_ activities: [FullFeedActivityDTO]) -> [FullFeedActivityDTO] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        return activities.filter { activity in
            // If the activity has an end time, keep it (let backend handle expiration)
            if activity.endTime != nil {
                return true
            }
            
            // If the activity has no end time (indefinite), check if it started before today
            guard let startTime = activity.startTime else {
                return false // Remove activities with no start time
            }
            
            // Keep indefinite activities that start today or in the future
            return startTime >= startOfToday
        }
    }
}
