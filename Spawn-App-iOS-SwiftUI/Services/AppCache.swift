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
    @Published var events: [Event] = []
    @Published var notifications: [NotificationDTO] = []
    
    // MARK: - Cache Metadata
    private var lastChecked: [String: Date] = [:]
    private var isInitialized = false
    
    // MARK: - Constants
    private enum CacheKeys {
        static let friends = "friends"
        static let events = "events"
        static let notifications = "notifications"
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
            let apiService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
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
                       let updatedEvents = try? JSONDecoder().decode([Event].self, from: updatedItems) {
                        // Backend provided the updated data
                        updateEvents(updatedEvents)
                    } else {
                        // Need to fetch new data
                        Task {
                            await refreshEvents()
                        }
                    }
                }
                
                if let notificationsResponse = result[CacheKeys.notifications], notificationsResponse.invalidate {
                    if let updatedItems = notificationsResponse.updatedItems,
                       let updatedNotifications = try? JSONDecoder().decode([NotificationDTO].self, from: updatedItems) {
                        // Backend provided the updated data
                        updateNotifications(updatedNotifications)
                    } else {
                        // Need to fetch new data
                        Task {
                            await refreshNotifications()
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
            let apiService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "friends/\(userId)") else { return }
            
            let fetchedFriends: [FullFriendUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateFriends(fetchedFriends)
            }
        } catch {
            print("Failed to refresh friends: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Events Methods
    
    func updateEvents(_ newEvents: [Event]) {
        events = newEvents
        lastChecked[CacheKeys.events] = Date()
        saveToDisk()
    }
    
    func refreshEvents() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "events/user/\(userId)") else { return }
            
            let fetchedEvents: [Event] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateEvents(fetchedEvents)
            }
        } catch {
            print("Failed to refresh events: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Notifications Methods
    
    func updateNotifications(_ newNotifications: [NotificationDTO]) {
        notifications = newNotifications
        lastChecked[CacheKeys.notifications] = Date()
        saveToDisk()
    }
    
    func refreshNotifications() async {
        guard let userId = UserAuthViewModel.shared.spawnUser?.id else { return }
        
        do {
            let apiService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
            guard let url = URL(string: APIService.baseURL + "notifications/\(userId)") else { return }
            
            let fetchedNotifications: [NotificationDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                updateNotifications(fetchedNotifications)
            }
        } catch {
            print("Failed to refresh notifications: \(error.localizedDescription)")
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
           let loadedEvents = try? JSONDecoder().decode([Event].self, from: eventsData) {
            events = loadedEvents
        }
        
        // Load notifications
        if let notificationsData = UserDefaults.standard.data(forKey: CacheKeys.notifications),
           let loadedNotifications = try? JSONDecoder().decode([NotificationDTO].self, from: notificationsData) {
            notifications = loadedNotifications
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
        
        // Save notifications
        if let notificationsData = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(notificationsData, forKey: CacheKeys.notifications)
        }
    }
} 