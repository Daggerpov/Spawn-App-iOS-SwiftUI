//
//  FeedViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation
import Combine

class FeedViewModel: ObservableObject {
    @Published var events: [FullFeedEventDTO] = []

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
            // Subscribe to AppCache events updates
            appCache.$events
                .sink { [weak self] cachedEvents in
                    if !cachedEvents.isEmpty {
                        // Convert Event to FullFeedEventDTO - this is a simplified conversion
                        let feedEvents = cachedEvents.map { event -> FullFeedEventDTO in
                            return FullFeedEventDTO(
                                id: event.id,
                                title: event.title,
                                startTime: event.startTime,
                                endTime: event.endTime,
                                location: event.location,
                                note: event.note,
                                creatorUser: event.creatorUser,
                                participantUsers: event.participantUsers,
                                chatMessages: nil
                            )
                        }
                        self?.events = feedEvents
                    }
                }
                .store(in: &cancellables)
        }
            
        // Register for event creation notifications
        NotificationCenter.default.publisher(for: .eventCreated)
            .sink { [weak self] _ in
                Task {
                    await self?.fetchEventsForUser()
                }
            }
            .store(in: &cancellables)
    }

    func fetchAllData() async {
        await fetchEventsForUser()
    }

    func fetchEventsForUser() async {
        // Check the cache first for unfiltered events
        if !appCache.events.isEmpty {
            // Convert Event to FullFeedEventDTO
            let feedEvents = appCache.events.map { event -> FullFeedEventDTO in
                return FullFeedEventDTO(
                    id: event.id,
                    title: event.title,
                    startTime: event.startTime,
                    endTime: event.endTime,
                    location: event.location,
                    note: event.note,
                    creatorUser: event.creatorUser,
                    participantUsers: event.participantUsers,
                    chatMessages: nil
                )
            }
            
            await MainActor.run {
                self.events = feedEvents
            }
            return
        }
        
        // If not in cache, fetch from API
        await fetchEventsFromAPI()
    }
    
    private func fetchEventsFromAPI() async {
        // Path: /api/v1/events/feedEvents/{requestingUserId}
        guard let url = URL(string: APIService.baseURL + "events/feedEvents/\(userId)") else {
            print("❌ DEBUG: Failed to construct URL for events")
            return
        }

        do {
            let fetchedEvents: [FullFeedEventDTO] = try await self.apiService.fetchData(
                from: url, parameters: nil
            )
            
            print("✅ DEBUG: Successfully fetched \(fetchedEvents.count) events")
            print("📍 DEBUG: Events with locations: \(fetchedEvents.filter { $0.location != nil }.count)")
            
            // Print location details for debugging
            fetchedEvents.forEach { event in
                print("🗺 DEBUG: Event '\(event.title ?? "Untitled")' location: \(event.location?.latitude ?? 0), \(event.location?.longitude ?? 0)")
            }

            // Convert FullFeedEventDTO to Event for caching
            let eventsForCache = fetchedEvents.map { event -> FullFeedEventDTO in
                return FullFeedEventDTO(
                    id: event.id,
                    title: event.title,
                    startTime: event.startTime,
                    endTime: event.endTime,
                    location: event.location,
                    note: event.note,
                    creatorUser: event.creatorUser,
                    participantUsers: event.participantUsers,
                    chatMessages: nil
                )
            }
            
            // Update the cache and view model
            await MainActor.run {
                self.events = fetchedEvents
                print("📱 DEBUG: Updated ViewModel with \(self.events.count) events")
                self.appCache.updateEvents(eventsForCache)
            }
        } catch {
            print("❌ DEBUG: Error fetching events: \(error)")
            await MainActor.run {
                self.events = []
            }
        }
    }
}
