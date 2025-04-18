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
    @Published var tags: [FullFriendTagDTO] = []
    @Published var activeTag: FullFriendTagDTO?

    var apiService: IAPIService
    var userId: UUID
    private var appCache: AppCache
    private var cancellables = Set<AnyCancellable>()

    init(apiService: IAPIService, userId: UUID) {
        self.apiService = apiService
        self.userId = userId
        self.appCache = AppCache.shared
        self._activeTag = Published(initialValue: nil)  // Initialize as nil since tags is empty
        
        // Subscribe to AppCache events updates
        appCache.$events
            .sink { [weak self] cachedEvents in
                if !cachedEvents.isEmpty && self?.activeTag == nil {
                    // Only use cache if this is the "Everyone" view (no active tag filter)
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
                            chatMessages: nil,
                            eventFriendTagColorHexCodeForRequestingUser: nil
                        )
                    }
                    self?.events = feedEvents
                }
            }
            .store(in: &cancellables)
    }

    func fetchAllData() async {
        await fetchEventsForUser()
        await fetchTagsForUser()
    }

    func fetchEventsForUser() async {
        // Check if we should use the filtered events or general events
        if let unwrappedActiveTag = activeTag, !unwrappedActiveTag.isEveryone {
            // Get events filtered by tag - this is not cached since it's a filtered view
            await fetchFilteredEvents(for: unwrappedActiveTag.id)
        } else {
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
                        chatMessages: nil,
                        eventFriendTagColorHexCodeForRequestingUser: nil
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
    }
    
    private func fetchFilteredEvents(for tagId: UUID) async {
        // Full path: /api/v1/events/friendTag/{friendTagFilterId}
        guard let url = URL(string: APIService.baseURL + "events/friendTag/\(tagId)") else {
            print("Failed to construct URL for filtered events")
            return
        }
        
        do {
            let fetchedEvents: [FullFeedEventDTO] = try await self.apiService.fetchData(
                from: url, parameters: nil
            )

            // Ensure updating on the main thread
            await MainActor.run {
                self.events = fetchedEvents
            }
        } catch {
            await MainActor.run {
                self.events = []
            }
        }
    }
    
    private func fetchEventsFromAPI() async {
        // Path: /api/v1/events/feedEvents/{requestingUserId}
        guard let url = URL(string: APIService.baseURL + "events/feedEvents/\(userId)") else {
            print("Failed to construct URL for events")
            return
        }

        do {
            let fetchedEvents: [FullFeedEventDTO] = try await self.apiService.fetchData(
                from: url, parameters: nil
            )

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
                    chatMessages: nil,
                    eventFriendTagColorHexCodeForRequestingUser: nil
                )
            }
            
            // Update the cache and view model
            await MainActor.run {
                self.events = fetchedEvents
                self.appCache.updateEvents(eventsForCache)
            }
        } catch {
            await MainActor.run {
                self.events = []
            }
        }
    }

    func fetchTagsForUser() async {
        // /api/v1/friendTags/owner/{ownerId}?full=full
        if let url = URL(
            string: APIService.baseURL + "friendTags/owner/\(userId)"
        ) {
            do {
                let fetchedTags: [FullFriendTagDTO] = try await self.apiService
                    .fetchData(from: url, parameters: nil)

                // Ensure updating on the main thread
                await MainActor.run {
                    self.tags = fetchedTags
                    self.activeTag = fetchedTags.first
                }
            } catch {
                await MainActor.run {
                    self.tags = []
                }
            }
        }
    }
}
