//
//  AppCache.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-04-20.
//

import Foundation
import SwiftUI
import Combine

/// A singleton cache manager that stores app data locally and checks for invalidation on app launch
class AppCache: ObservableObject {
    static let shared = AppCache()
    
    // MARK: - Cached Data
    @Published var friends: [FullFriendUserDTO] = []
    @Published var events: [FullFeedEventDTO] = []
    @Published var recommendedFriends: [RecommendedFriendUserDTO] = []
    @Published var friendRequests: [FetchFriendRequestDTO] = []
    @Published var otherProfiles: [UUID: BaseUserDTO] = [:]
    
    // Profile caches
    @Published var profileStats: [UUID: UserStatsDTO] = [:]
    @Published var profileInterests: [UUID: [String]] = [:]
    @Published var profileSocialMedia: [UUID: UserSocialMediaDTO] = [:]
    @Published var profileEvents: [UUID: [ProfileEventDTO]] = [:]
    
    // MARK: - Cache Metadata
    private var lastChecked: [String: Date] = [:]
    private var isInitialized = false
    
    // MARK: - Constants
    private enum CacheKeys {
        static let lastChecked = "lastChecked"
        static let friends = "friends"
        static let events = "events"
        static let recommendedFriends = "recommendedFriends"
        static let friendRequests = "friendRequests"
        static let otherProfiles = "otherProfiles"
        static let profileStats = "profileStats"
        static let profileInterests = "profileInterests"
        static let profileSocialMedia = "profileSocialMedia"
        static let profileEvents = "profileEvents"
    }
    
    private init() {
        loadFromDisk()
        
        // Set up a timer to periodically save to disk
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.saveToDisk()
        }
    }
    
    // MARK: - Public Methods
    
    /// Initialize the cache and load from disk
    func initialize() {
        if !isInitialized {
            loadFromDisk()
            isInitialized = true
        }
    }
    
    /// Validate cache with backend and refresh stale items
    func validateCache() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else {
            print("Cannot validate cache: No logged in user")
            return
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            let result = try await apiService.validateCache(lastChecked)
            
            await MainActor.run {
                // Update each collection based on invalidation results
                if let friendsResponse = result[CacheKeys.friends], friendsResponse.invalidate {
                    if let updatedItems = friendsResponse.updatedItems,
                       let updatedFriends = try? JSONDecoder().decode([FullFriendUserDTO].self, from: updatedItems) {
                        // Backend provided the updated data
                        updateFriends(updatedFriends)
                    } else {
                        // Need to fetch new data
                        Task {
                            await refreshFriends()
                        }
                    }
                }
                
                if let eventsResponse = result[CacheKeys.events], eventsResponse.invalidate {
                    if let updatedItems = eventsResponse.updatedItems,
                       let updatedEvents = try? JSONDecoder().decode([FullFeedEventDTO].self, from: updatedItems) {
                        // Backend provided the updated data
                        updateEvents(updatedEvents)
                    } else {
                        // Need to fetch new data
                        Task {
                            await refreshEvents()
                        }
                    }
                }
                
                // Other Profiles Cache
                if let otherProfilesResponse = result[CacheKeys.otherProfiles], otherProfilesResponse.invalidate {
                    Task {
                        await refreshOtherProfiles()
                    }
                }
                
                // Recommended Friends Cache
                if let recommendedFriendsResponse = result[CacheKeys.recommendedFriends], recommendedFriendsResponse.invalidate {
                    if let updatedItems = recommendedFriendsResponse.updatedItems,
                       let updatedRecommendedFriends = try? JSONDecoder().decode([RecommendedFriendUserDTO].self, from: updatedItems) {
                        updateRecommendedFriends(updatedRecommendedFriends)
                    } else {
                        Task {
                            await refreshRecommendedFriends()
                        }
                    }
                }
                
                // Friend Requests Cache
                if let friendRequestsResponse = result[CacheKeys.friendRequests], friendRequestsResponse.invalidate {
                    if let updatedItems = friendRequestsResponse.updatedItems,
                       let updatedFriendRequests = try? JSONDecoder().decode([FetchFriendRequestDTO].self, from: updatedItems) {
                        updateFriendRequests(updatedFriendRequests)
                    } else {
                        Task {
                            await refreshFriendRequests()
                        }
                    }
                }
            }
            
        } catch {
            print("Failed to validate cache: \(error.localizedDescription)")
            // If validation fails, we'll continue using cached data
        }
    }
    
    // MARK: - Friends Methods
    
    func updateFriends(_ newFriends: [FullFriendUserDTO]) {
        friends = newFriends
        lastChecked[CacheKeys.friends] = Date()
        saveToDisk()
    }
    
    func refreshFriends() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/friends/\(userId)") else { return }
            
            let fetchedFriends: [FullFriendUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateFriends(fetchedFriends)
            }
        } catch {
            print("Failed to refresh friends: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Events Methods
    
    func updateEvents(_ newEvents: [FullFeedEventDTO]) {
        events = newEvents
        lastChecked[CacheKeys.events] = Date()
        saveToDisk()
    }
    
    func refreshEvents() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "events/feedEvents/\(userId)") else { return }
            
            let fetchedEvents: [FullFeedEventDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateEvents(fetchedEvents)
            }
        } catch {
            print("Failed to refresh events: \(error.localizedDescription)")
        }
    }
    
    // Get an event by ID from the cache
    func getEventById(_ eventId: UUID) -> FullFeedEventDTO? {
        return events.first { $0.id == eventId }
    }
    
    // Add or update an event in the cache
    func addOrUpdateEvent(_ event: FullFeedEventDTO) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }
        lastChecked[CacheKeys.events] = Date()
        saveToDisk()
    }
    
    // MARK: - Other Profiles Methods
    
    func updateOtherProfile(_ userId: UUID, _ profile: BaseUserDTO) {
        otherProfiles[userId] = profile
        lastChecked[CacheKeys.otherProfiles] = Date()
        saveToDisk()
    }
    
    func refreshOtherProfiles() async {
        // Since this is a collection of individual profiles,
        // we'll refresh all the profiles we currently have cached
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: myUserId) : APIService()
        
        var usersToRemove: [UUID] = []
        
        for userId in otherProfiles.keys {
            do {
                guard let url = URL(string: APIService.baseURL + "users/\(userId)") else { continue }
                let fetchedProfile: BaseUserDTO = try await apiService.fetchData(from: url, parameters: nil)
                
                await MainActor.run {
                    otherProfiles[userId] = fetchedProfile
                }
            } catch let error as APIError {
                // If user not found (404), mark for removal from cache
                if case .invalidStatusCode(let statusCode) = error, statusCode == 404 {
                    print("User with ID \(userId) no longer exists, removing from cache")
                    usersToRemove.append(userId)
                } else {
                    print("Failed to refresh profile for user \(userId): \(error.localizedDescription)")
                }
            } catch {
                print("Failed to refresh profile for user \(userId): \(error.localizedDescription)")
            }
        }

		for userId in usersToRemove{
			otherProfiles.removeValue(forKey: userId)
		}

        await MainActor.run {
            lastChecked[CacheKeys.otherProfiles] = Date()
            saveToDisk()
        }
    }
    
    // MARK: - Recommended Friends Methods
    
    func updateRecommendedFriends(_ newRecommendedFriends: [RecommendedFriendUserDTO]) {
        recommendedFriends = newRecommendedFriends
        lastChecked[CacheKeys.recommendedFriends] = Date()
        saveToDisk()
    }
    
    func refreshRecommendedFriends() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/recommended-friends/\(userId)") else { return }
            
            let fetchedRecommendedFriends: [RecommendedFriendUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateRecommendedFriends(fetchedRecommendedFriends)
            }
        } catch {
            print("Failed to refresh recommended friends: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Friend Requests Methods
    
    func updateFriendRequests(_ newFriendRequests: [FetchFriendRequestDTO]) {
        friendRequests = newFriendRequests
        lastChecked[CacheKeys.friendRequests] = Date()
        saveToDisk()
    }
    
    func refreshFriendRequests() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "friend-requests/incoming/\(userId)") else { return }
            
            let fetchedFriendRequests: [FetchFriendRequestDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateFriendRequests(fetchedFriendRequests)
            }
        } catch {
            print("Failed to refresh friend requests: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Profile Methods
    
    func updateProfileStats(_ userId: UUID, _ stats: UserStatsDTO) {
        profileStats[userId] = stats
        lastChecked[CacheKeys.profileStats] = Date()
        saveToDisk()
    }
    
    func updateProfileInterests(_ userId: UUID, _ interests: [String]) {
        profileInterests[userId] = interests
        lastChecked[CacheKeys.profileInterests] = Date()
        saveToDisk()
    }
    
    func updateProfileSocialMedia(_ userId: UUID, _ socialMedia: UserSocialMediaDTO) {
        profileSocialMedia[userId] = socialMedia
        lastChecked[CacheKeys.profileSocialMedia] = Date()
        saveToDisk()
    }
    
    func updateProfileEvents(_ userId: UUID, _ events: [ProfileEventDTO]) {
        profileEvents[userId] = events
        lastChecked[CacheKeys.profileEvents] = Date()
        saveToDisk()
    }
    
    func refreshProfileStats(_ userId: UUID) async {
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: myUserId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/\(userId)/stats") else { return }
            
            let stats: UserStatsDTO = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateProfileStats(userId, stats)
            }
        } catch {
            print("Failed to refresh profile stats: \(error.localizedDescription)")
        }
    }
    
    func refreshProfileInterests(_ userId: UUID) async {
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: myUserId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/\(userId)/interests") else { return }
            
            let interests: [String] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateProfileInterests(userId, interests)
            }
        } catch {
            print("Failed to refresh profile interests: \(error.localizedDescription)")
        }
    }
    
    func refreshProfileSocialMedia(_ userId: UUID) async {
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: myUserId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/\(userId)/social-media") else { return }
            
            let socialMedia: UserSocialMediaDTO = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateProfileSocialMedia(userId, socialMedia)
            }
        } catch {
            print("Failed to refresh profile social media: \(error.localizedDescription)")
        }
    }
    
    func refreshProfileEvents(_ userId: UUID) async {
        guard let myUserId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: myUserId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/profile/\(userId)") else { return }
            let parameters = ["requestingUserId": myUserId.uuidString]
            
            let events: [ProfileEventDTO] = try await apiService.fetchData(from: url, parameters: parameters)
            
            await MainActor.run {
                updateProfileEvents(userId, events)
            }
        } catch {
            print("Failed to refresh profile events: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Persistence
    
    private func loadFromDisk() {
        // Load cache timestamps
        if let timestampsData = UserDefaults.standard.data(forKey: CacheKeys.lastChecked),
           let loadedTimestamps = try? JSONDecoder().decode([String: Date].self, from: timestampsData) {
            lastChecked = loadedTimestamps
        }
        
        // Load friends
        if let friendsData = UserDefaults.standard.data(forKey: CacheKeys.friends),
           let loadedFriends = try? JSONDecoder().decode([FullFriendUserDTO].self, from: friendsData) {
            friends = loadedFriends
        }
        
        // Load events
        if let eventsData = UserDefaults.standard.data(forKey: CacheKeys.events),
           let loadedEvents = try? JSONDecoder().decode([FullFeedEventDTO].self, from: eventsData) {
            events = loadedEvents
        }
        
        // Load other profiles
        if let profilesData = UserDefaults.standard.data(forKey: CacheKeys.otherProfiles),
           let loadedProfiles = try? JSONDecoder().decode([UUID: BaseUserDTO].self, from: profilesData) {
            otherProfiles = loadedProfiles
        }
        
        // Load recommended friends
        if let recommendedData = UserDefaults.standard.data(forKey: CacheKeys.recommendedFriends),
           let loadedRecommended = try? JSONDecoder().decode([RecommendedFriendUserDTO].self, from: recommendedData) {
            recommendedFriends = loadedRecommended
        }
        
        // Load friend requests
        if let requestsData = UserDefaults.standard.data(forKey: CacheKeys.friendRequests),
           let loadedRequests = try? JSONDecoder().decode([FetchFriendRequestDTO].self, from: requestsData) {
            friendRequests = loadedRequests
        }
        
        // Load profile stats
        if let statsData = UserDefaults.standard.data(forKey: CacheKeys.profileStats),
           let loadedStats = try? JSONDecoder().decode([UUID: UserStatsDTO].self, from: statsData) {
            profileStats = loadedStats
        }
        
        // Load profile interests
        if let interestsData = UserDefaults.standard.data(forKey: CacheKeys.profileInterests),
           let loadedInterests = try? JSONDecoder().decode([UUID: [String]].self, from: interestsData) {
            profileInterests = loadedInterests
        }
        
        // Load profile social media
        if let socialMediaData = UserDefaults.standard.data(forKey: CacheKeys.profileSocialMedia),
           let loadedSocialMedia = try? JSONDecoder().decode([UUID: UserSocialMediaDTO].self, from: socialMediaData) {
            profileSocialMedia = loadedSocialMedia
        }
        
        // Load profile events
        if let eventsData = UserDefaults.standard.data(forKey: CacheKeys.profileEvents),
           let loadedEvents = try? JSONDecoder().decode([UUID: [ProfileEventDTO]].self, from: eventsData) {
            profileEvents = loadedEvents
        }
    }
    
    private func saveToDisk() {
        // Save cache timestamps
        if let timestampsData = try? JSONEncoder().encode(lastChecked) {
            UserDefaults.standard.set(timestampsData, forKey: CacheKeys.lastChecked)
        }
        
        // Save friends
        if let friendsData = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(friendsData, forKey: CacheKeys.friends)
        }
        
        // Save events
        if let eventsData = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(eventsData, forKey: CacheKeys.events)
        }
        
        // Save other profiles
        if let profilesData = try? JSONEncoder().encode(otherProfiles) {
            UserDefaults.standard.set(profilesData, forKey: CacheKeys.otherProfiles)
        }
        
        // Save recommended friends
        if let recommendedData = try? JSONEncoder().encode(recommendedFriends) {
            UserDefaults.standard.set(recommendedData, forKey: CacheKeys.recommendedFriends)
        }
        
        // Save friend requests
        if let requestsData = try? JSONEncoder().encode(friendRequests) {
            UserDefaults.standard.set(requestsData, forKey: CacheKeys.friendRequests)
        }
        
        // Save profile stats
        if let statsData = try? JSONEncoder().encode(profileStats) {
            UserDefaults.standard.set(statsData, forKey: CacheKeys.profileStats)
        }
        
        // Save profile interests
        if let interestsData = try? JSONEncoder().encode(profileInterests) {
            UserDefaults.standard.set(interestsData, forKey: CacheKeys.profileInterests)
        }
        
        // Save profile social media
        if let socialMediaData = try? JSONEncoder().encode(profileSocialMedia) {
            UserDefaults.standard.set(socialMediaData, forKey: CacheKeys.profileSocialMedia)
        }
        
        // Save profile events
        if let eventsData = try? JSONEncoder().encode(profileEvents) {
            UserDefaults.standard.set(eventsData, forKey: CacheKeys.profileEvents)
        }
    }
} 
