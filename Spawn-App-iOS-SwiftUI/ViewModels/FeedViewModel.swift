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

    var apiService: IAPIService
    var userId: UUID
    private var appCache: AppCache
    private var cancellables = Set<AnyCancellable>()

    init(apiService: IAPIService, userId: UUID) {
        self.apiService = apiService
        self.userId = userId
        self.appCache = AppCache.shared
        
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
            
            print("✅ DEBUG: Successfully fetched \(fetchedActivities.count) activities")
            print("📍 DEBUG: Activities with locations: \(fetchedActivities.filter { $0.location != nil }.count)")
            
            // Print location details for debugging
            fetchedActivities.forEach { activity in
                print("🗺 DEBUG: Activity '\(activity.title ?? "Untitled")' location: \(activity.location?.latitude ?? 0), \(activity.location?.longitude ?? 0)")
            }
            
            // Update the cache and view model
            await MainActor.run {
                self.activities = fetchedActivities
                print("📱 DEBUG: Updated ViewModel with \(self.activities.count) activities")
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
