//
//  DayActivitiesViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-05.
//

import Foundation
import Combine
import SwiftUI

class DayActivitiesViewModel: ObservableObject {
    @Published var activities: [CalendarActivityDTO] = []
    @Published var headerTitle: String = "Activities"
    @Published private var fetchedActivities: [UUID: FullFeedActivityDTO] = [:]
    
    private var appCache: AppCache
    private var apiService: IAPIService
    private var cancellables = Set<AnyCancellable>()
    
    init(apiService: IAPIService, activities: [CalendarActivityDTO]) {
        self.apiService = apiService
        self.activities = activities
        self.appCache = AppCache.shared
        
        // Set the header title when initialized
        updateHeaderTitle()

		if !MockAPIService.isMocking {
			
			// Subscribe to changes in the app cache activities
			appCache.$activities
				.sink { [weak self] _ in
					self?.updateCachedActivities()
				}
				.store(in: &cancellables)
		}
    }
    
    // Format the date for display in the header
    private func updateHeaderTitle() {
        if let firstActivity = activities.first {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            headerTitle = formatter.string(from: firstActivity.date)
        } else {
            headerTitle = "Activities"
        }
    }
    
    // Format a specific date
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    // Fetch all activities directly via API without checking cache
    func loadActivitiesIfNeeded() async {
        for activity in activities {
            guard let activityId = activity.activityId else { continue }
            
            // Always fetch activity details via API
            await fetchActivity(activityId)
        }
    }
    
    private func updateCachedActivities() {
        // This method is still useful for tracking which activities are currently loading
        // However, we now ignore the cache check and just update based on completed API calls
    }
    
    func fetchActivity(_ activityId: UUID) async {
        
        let apiService: IAPIService = MockAPIService.isMocking
            ? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())
            : APIService()
        
        do {
            let urlString = "\(APIService.baseURL)activities/\(activityId)"
            if let url = URL(string: urlString) {
                let activity: FullFeedActivityDTO = try await apiService.fetchData(
                    from: url,
                    parameters: ["requestingUserId": UserAuthViewModel.shared.spawnUser?.id.uuidString ?? UUID().uuidString]
                )
                await MainActor.run {
                    // Store in our own dictionary instead of app cache
                    fetchedActivities[activityId] = activity
                    
                    // Also update app cache for compatibility with other parts of the app
                    appCache.addOrUpdateActivity(activity)
                    
                }
            }
        } catch {
            print("Error fetching activity: \(error.localizedDescription)")
        }
    }
    
    func getActivity(for activityId: UUID) -> FullFeedActivityDTO? {
        // First check our own fetched activities
        if let activity = fetchedActivities[activityId] {
            return activity
        }
        
        // No need to check app cache since we're making direct API calls
        return nil
    }
    
    func isActivityLoading(_ activityId: UUID) -> Bool {
        // An activity is considered loading if it's not in our fetchedActivities dictionary
        // and we have been asked to fetch it (which is implied by checking)
        return fetchedActivities[activityId] == nil
    }
} 