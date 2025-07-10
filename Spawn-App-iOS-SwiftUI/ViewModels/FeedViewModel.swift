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
                .sink { [weak self] cachedActivities in
                    if !cachedActivities.isEmpty {
                        self?.activities = cachedActivities
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
    }

    func fetchAllData() async {
        await fetchActivitiesForUser()
        await activityTypeViewModel.fetchActivityTypes()
    }

    func fetchActivitiesForUser() async {
        // Check the cache first for unfiltered activities
        if !appCache.activities.isEmpty {
            await MainActor.run {
                self.activities = appCache.activities
            }
            return
        }
        
        // If not in cache, fetch from API
        await fetchActivitiesFromAPI()
    }
    

    
    private func fetchActivitiesFromAPI() async {
        // Path: /api/v1/activities/feedActivities/{requestingUserId}
        guard let url = URL(string: APIService.baseURL + "activities/feedActivities/\(userId)") else {
            print("❌ DEBUG: Failed to construct URL for activities")
            return
        }

        do {
            let fetchedActivities: [FullFeedActivityDTO] = try await self.apiService.fetchData(
                from: url, parameters: nil
            )
            
            // Update the cache and view model
            await MainActor.run {
                self.activities = fetchedActivities
                self.appCache.updateActivities(fetchedActivities)
            }
        } catch {
            print("❌ DEBUG: Error fetching activities: \(error)")
            await MainActor.run {
                self.activities = []
            }
        }
    }
}
