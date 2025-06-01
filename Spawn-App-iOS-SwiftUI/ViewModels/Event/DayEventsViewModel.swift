//
//  DayEventsViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-05.
//

import Foundation
import Combine
import SwiftUI

class DayEventsViewModel: ObservableObject {
    @Published var activities: [CalendarActivityDTO] = []
    @Published var headerTitle: String = "Events"
    @Published private var fetchedEvents: [UUID: FullFeedEventDTO] = [:]
    
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
			
			// Subscribe to changes in the app cache events
			appCache.$events
				.sink { [weak self] _ in
					self?.updateCachedEvents()
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
            headerTitle = "Events"
        }
    }
    
    // Format a specific date
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    // Fetch all events directly via API without checking cache
    func loadEventsIfNeeded() async {
        for activity in activities {
            guard let eventId = activity.eventId else { continue }
            
            // Always fetch event details via API
            await fetchEvent(eventId)
        }
    }
    
    private func updateCachedEvents() {
        // This method is still useful for tracking which events are currently loading
        // However, we now ignore the cache check and just update based on completed API calls
    }
    
    func fetchEvent(_ eventId: UUID) async {
        
        let apiService: IAPIService = MockAPIService.isMocking
            ? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())
            : APIService()
        
        do {
            let urlString = "\(APIService.baseURL)events/\(eventId)"
            if let url = URL(string: urlString) {
                let event: FullFeedEventDTO = try await apiService.fetchData(
                    from: url,
                    parameters: ["requestingUserId": UserAuthViewModel.shared.spawnUser?.id.uuidString ?? UUID().uuidString]
                )
                await MainActor.run {
                    // Store in our own dictionary instead of app cache
                    fetchedEvents[eventId] = event
                    
                    // Also update app cache for compatibility with other parts of the app
                    appCache.addOrUpdateEvent(event)
                    
                }
            }
        } catch {
            print("Error fetching event: \(error.localizedDescription)")
        }
    }
    
    func getEvent(for eventId: UUID) -> FullFeedEventDTO? {
        // First check our own fetched events
        if let event = fetchedEvents[eventId] {
            return event
        }
        
        // No need to check app cache since we're making direct API calls
        return nil
    }
    
    func isEventLoading(_ eventId: UUID) -> Bool {
        // An event is considered loading if it's not in our fetchedEvents dictionary
        // and we have been asked to fetch it (which is implied by checking)
        return fetchedEvents[eventId] == nil
    }
}
