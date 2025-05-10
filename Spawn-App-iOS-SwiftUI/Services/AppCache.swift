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
    @Published var profilePicture: BaseUserDTO?
    @Published var otherProfiles: [UUID: BaseUserDTO] = [:]
    @Published var recommendedFriends: [RecommendedFriendUserDTO] = []
    @Published var friendRequests: [FetchFriendRequestDTO] = []
    @Published var userTags: [FriendTagDTO] = []
    @Published var tagFriends: [UUID: [FullFriendUserDTO]] = [:] // Tag ID -> Friends in tag
    
    // MARK: - Cache Metadata
    private var lastChecked: [String: Date] = [:]
    private var isInitialized = false
    
    // MARK: - Constants
    private enum CacheKeys {
        static let friends = "friends"
        static let events = "events"
        static let profilePicture = "profilePicture"
        static let otherProfiles = "otherProfiles"
        static let recommendedFriends = "recommendedFriends"
        static let friendRequests = "friendRequests"
        static let userTags = "userTags"
        static let tagFriends = "tagFriends"
        static let lastChecked = "cache_last_checked"
    }
    
    private init() {
        loadFromDisk()
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
                
                // Profile Picture Cache
                if let profilePictureResponse = result[CacheKeys.profilePicture], profilePictureResponse.invalidate {
                    if let updatedItems = profilePictureResponse.updatedItems,
                       let updatedProfile = try? JSONDecoder().decode(BaseUserDTO.self, from: updatedItems) {
                        updateProfilePicture(updatedProfile)
                    } else {
                        Task {
                            await refreshProfilePicture()
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
                
                // User Tags Cache
                if let userTagsResponse = result[CacheKeys.userTags], userTagsResponse.invalidate {
                    if let updatedItems = userTagsResponse.updatedItems,
                       let updatedUserTags = try? JSONDecoder().decode([FriendTagDTO].self, from: updatedItems) {
                        updateUserTags(updatedUserTags)
                    } else {
                        Task {
                            await refreshUserTags()
                        }
                    }
                }
                
                // Tag Friends Cache
                if let tagFriendsResponse = result[CacheKeys.tagFriends], tagFriendsResponse.invalidate {
                    Task {
                        await refreshTagFriends()
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
    
    // MARK: - Profile Picture Methods
    
    func updateProfilePicture(_ newProfile: BaseUserDTO) {
        profilePicture = newProfile
        lastChecked[CacheKeys.profilePicture] = Date()
        saveToDisk()
    }
    
    func refreshProfilePicture() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh profile picture: No user ID available")
            return 
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "users/\(userId)") else { 
                print("Invalid URL for refreshing profile picture")
                return 
            }
            
            print("Refreshing profile picture for user \(userId)")
            let fetchedProfile: BaseUserDTO = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                print("Successfully fetched profile picture: \(fetchedProfile.profilePicture ?? "nil")")
                updateProfilePicture(fetchedProfile)
            }
        } catch let error as APIError {
            if case .invalidStatusCode(let code) = error, code == 401 {
                print("Failed to refresh profile picture: Authentication error (401)")
                // Token issue - notify the user or attempt to re-authenticate
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .userAuthenticationFailed, object: nil)
                }
            } else if case .failedTokenSaving = error {
                print("Failed to refresh profile picture: JWT token saving error")
                // Token saving issue
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .userAuthenticationFailed, object: nil)
                }
            } else {
                print("Failed to refresh profile picture: \(error.localizedDescription)")
            }
        } catch {
            print("Failed to refresh profile picture: \(error.localizedDescription)")
        }
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
        
        for userId in otherProfiles.keys {
            do {
                guard let url = URL(string: APIService.baseURL + "users/\(userId)") else { continue }
                let fetchedProfile: BaseUserDTO = try await apiService.fetchData(from: url, parameters: nil)
                
                await MainActor.run {
                    otherProfiles[userId] = fetchedProfile
                }
            } catch {
                print("Failed to refresh profile for user \(userId): \(error.localizedDescription)")
            }
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
    
    // MARK: - User Tags Methods
    
    func updateUserTags(_ newUserTags: [FriendTagDTO]) {
        userTags = newUserTags
        lastChecked[CacheKeys.userTags] = Date()
        saveToDisk()
    }
    
    func refreshUserTags() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { 
            print("Cannot refresh user tags: No user ID available")
            return 
        }
        
        do {
            let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "friend-tags/owner/\(userId)") else { 
                print("Invalid URL for refreshing user tags")
                return 
            }
            
            print("Refreshing user tags for user \(userId)")
            let fetchedUserTags: [FriendTagDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                print("Successfully fetched \(fetchedUserTags.count) user tags")
                updateUserTags(fetchedUserTags)
            }
        } catch let error as APIError {
            if case .invalidStatusCode(let code) = error, code == 401 {
                print("Failed to refresh user tags: Authentication error (401)")
                // Token issue - notify the user or attempt to re-authenticate
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .userAuthenticationFailed, object: nil)
                }
            } else {
                print("Failed to refresh user tags: \(error.localizedDescription)")
            }
        } catch {
            print("Failed to refresh user tags: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Tag Friends Methods
    
    func updateTagFriends(_ tagId: UUID, _ friends: [FullFriendUserDTO]) {
        tagFriends[tagId] = friends
        lastChecked[CacheKeys.tagFriends] = Date()
        saveToDisk()
    }
    
    func refreshTagFriends() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
        
        // Refresh friends for each tag
        for tag in userTags {
            do {
                guard let url = URL(string: APIService.baseURL + "friend-tags/\(tag.id)/friends") else { continue }
                
                let fetchedTagFriends: [FullFriendUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
                
                await MainActor.run {
                    tagFriends[tag.id] = fetchedTagFriends
                }
            } catch {
                print("Failed to refresh friends for tag \(tag.id): \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            lastChecked[CacheKeys.tagFriends] = Date()
            saveToDisk()
        }
    }
    
    // MARK: - Persistence
    
    private func loadFromDisk() {
        // Load cache timestamps
        if let timestampsData = UserDefaults.standard.data(forKey: CacheKeys.lastChecked),
           let timestamps = try? JSONDecoder().decode([String: Date].self, from: timestampsData) {
            lastChecked = timestamps
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
       
        // Load profile picture
        if let profileData = UserDefaults.standard.data(forKey: CacheKeys.profilePicture),
           let loadedProfile = try? JSONDecoder().decode(BaseUserDTO.self, from: profileData) {
            profilePicture = loadedProfile
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
        
        // Load user tags
        if let tagsData = UserDefaults.standard.data(forKey: CacheKeys.userTags),
           let loadedTags = try? JSONDecoder().decode([FriendTagDTO].self, from: tagsData) {
            userTags = loadedTags
        }
        
        // Load tag friends
        if let tagFriendsData = UserDefaults.standard.data(forKey: CacheKeys.tagFriends),
           let loadedTagFriends = try? JSONDecoder().decode([UUID: [FullFriendUserDTO]].self, from: tagFriendsData) {
            tagFriends = loadedTagFriends
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
        
        // Save profile picture
        if let profilePicture = profilePicture,
           let profileData = try? JSONEncoder().encode(profilePicture) {
            UserDefaults.standard.set(profileData, forKey: CacheKeys.profilePicture)
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
        
        // Save user tags
        if let tagsData = try? JSONEncoder().encode(userTags) {
            UserDefaults.standard.set(tagsData, forKey: CacheKeys.userTags)
        }
        
        // Save tag friends
        if let tagFriendsData = try? JSONEncoder().encode(tagFriends) {
            UserDefaults.standard.set(tagFriendsData, forKey: CacheKeys.tagFriends)
        }
    }
} 
