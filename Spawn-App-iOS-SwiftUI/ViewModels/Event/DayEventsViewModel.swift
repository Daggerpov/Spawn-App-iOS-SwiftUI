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
    @Published var loadingEvents: Set<UUID> = []
    @Published var headerTitle: String = "Events"
    
    private var appCache: AppCache
    private var apiService: IAPIService
    private var cancellables = Set<AnyCancellable>()
    
    init(apiService: IAPIService, activities: [CalendarActivityDTO]) {
        self.apiService = apiService
        self.activities = activities
        self.appCache = AppCache.shared
        
        // Set the header title when initialized
        updateHeaderTitle()
        
        // Subscribe to changes in the app cache events
        appCache.$events
            .sink { [weak self] _ in
                self?.updateCachedEvents()
            }
            .store(in: &cancellables)
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
    
    // Pre-check cache and fetch any missing events
    func loadEventsIfNeeded() async {
        for activity in activities {
            guard let eventId = activity.eventId else { continue }
            
            if appCache.getEventById(eventId) == nil {
                await fetchEvent(eventId)
            }
        }
    }
    
    private func updateCachedEvents() {
        // Clear any loading events that are now in the cache
        var newLoadingEvents = loadingEvents
        
        for eventId in loadingEvents {
            if appCache.getEventById(eventId) != nil {
                newLoadingEvents.remove(eventId)
            }
        }
        
        DispatchQueue.main.async {
            self.loadingEvents = newLoadingEvents
        }
    }
    
    func fetchEvent(_ eventId: UUID) async {
        // Add to loading set
        await MainActor.run {
            loadingEvents.insert(eventId)
        }
        
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
                    appCache.addOrUpdateEvent(event)
                    loadingEvents.remove(eventId)
                }
            }
        } catch {
            print("Error fetching event: \(error.localizedDescription)")
            await MainActor.run {
                loadingEvents.remove(eventId)
            }
        }
    }
    
    
    
    func isEventLoading(_ eventId: UUID) -> Bool {
        return loadingEvents.contains(eventId)
    }
} 
