//
//  FriendRequestsViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-17.
//

import Foundation
import Combine

class FriendRequestsViewModel: ObservableObject {
    @Published var incomingFriendRequests: [FetchFriendRequestDTO] = []
    @Published var sentFriendRequests: [FetchFriendRequestDTO] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private var apiService: IAPIService
    private let userId: UUID
    private var appCache: AppCache
    private var cancellables = Set<AnyCancellable>()
    
    init(userId: UUID, apiService: IAPIService = MockAPIService.isMocking ? MockAPIService() : APIService()) {
        self.userId = userId
        self.apiService = apiService
        self.appCache = AppCache.shared
        
        // Removed AppCache subscriptions to ensure API results drive UI state for friend requests
        
        // Initialize cache with mock data if in mock mode and cache is empty
        if MockAPIService.isMocking {
            initializeMockDataInCache()
        }
    }
    
    private func initializeMockDataInCache() {
        // Only initialize if cache is empty for this user
        let currentIncoming = appCache.friendRequests[userId] ?? []
        let currentSent = appCache.sentFriendRequests[userId] ?? []
        
        if currentIncoming.isEmpty && currentSent.isEmpty {
            // Initialize cache with mock data for this specific user
            appCache.updateFriendRequestsForUser(FetchFriendRequestDTO.mockFriendRequests, userId: userId)
            appCache.updateSentFriendRequestsForUser(FetchFriendRequestDTO.mockSentFriendRequests, userId: userId)
        }
    }
    
    @MainActor
    func fetchFriendRequests() async {
        isLoading = true
        defer { isLoading = false }
        
        // Always fetch fresh data from API to ensure we have the latest information
        do {
            // Fetch incoming friend requests
            guard let incomingUrl = URL(string: APIService.baseURL + "friend-requests/incoming/\(userId)") else {
                errorMessage = "Invalid URL for incoming requests"
                return
            }
            
            // Fetch sent friend requests
            guard let sentUrl = URL(string: APIService.baseURL + "friend-requests/sent/\(userId)") else {
                errorMessage = "Invalid URL for sent requests"
                return
            }
            
            async let incoming: [FetchFriendRequestDTO] = apiService.fetchData(from: incomingUrl, parameters: nil)
            async let sent: [FetchFriendRequestDTO] = apiService.fetchData(from: sentUrl, parameters: nil)
            
            let (fetchedIncomingRequests, fetchedSentRequests) = try await (incoming, sent)
            
            // Update UI first, then cache (do not filter out zero UUIDs here)
            self.incomingFriendRequests = fetchedIncomingRequests
            self.sentFriendRequests = fetchedSentRequests
            
            // Update cache for both incoming and sent requests
            appCache.updateFriendRequestsForUser(fetchedIncomingRequests, userId: userId)
            appCache.updateSentFriendRequestsForUser(fetchedSentRequests, userId: userId)
            
            // Fallback to cache if API returned empty but cache has data
            if self.incomingFriendRequests.isEmpty {
                let cachedIncoming = appCache.getCurrentUserFriendRequests()
                if !cachedIncoming.isEmpty { self.incomingFriendRequests = cachedIncoming }
            }
            if self.sentFriendRequests.isEmpty {
                let cachedSent = appCache.getCurrentUserSentFriendRequests()
                if !cachedSent.isEmpty { self.sentFriendRequests = cachedSent }
            }
            
        } catch {
            errorMessage = "Failed to fetch friend requests: \(error.localizedDescription)"
            if MockAPIService.isMocking {
                // Fallback to mock data in mock environment
                self.incomingFriendRequests = FetchFriendRequestDTO.mockFriendRequests
                self.sentFriendRequests = FetchFriendRequestDTO.mockSentFriendRequests
            } else {
                // Fallback to cache to avoid showing empty lists if we have cached data
                let cachedIncoming = appCache.getCurrentUserFriendRequests()
                let cachedSent = appCache.getCurrentUserSentFriendRequests()
                if !cachedIncoming.isEmpty || !cachedSent.isEmpty {
                    self.incomingFriendRequests = cachedIncoming
                    self.sentFriendRequests = cachedSent
                } else {
                    self.incomingFriendRequests = []
                    self.sentFriendRequests = []
                }
            }
        }
    }
    
    @MainActor
    func respondToFriendRequest(requestId: UUID, action: FriendRequestAction) async {
        let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        if requestId == zeroUUID { return }
        do {
            guard let url = URL(string: APIService.baseURL + "friend-requests/\(requestId)") else {
                errorMessage = "Invalid URL"
                return
            }
            
            let beforeIncoming = incomingFriendRequests.count
            let beforeSent = sentFriendRequests.count
            
            if action == .cancel {
                try await apiService.deleteData(from: url, parameters: nil, object: Optional<String>.none)
            } else {
                let _: EmptyResponse = try await apiService.updateData(
                    EmptyRequestBody(),
                    to: url,
                    parameters: ["friendRequestAction": action.rawValue]
                )
            }
            
            // Remove the request from both lists (it could be in either)
            self.incomingFriendRequests.removeAll { $0.id == requestId }
            self.sentFriendRequests.removeAll { $0.id == requestId }
            
            // Update the cache with the modified friend requests
            appCache.updateFriendRequestsForUser(self.incomingFriendRequests, userId: userId)
            appCache.updateSentFriendRequestsForUser(self.sentFriendRequests, userId: userId)
            
            let afterIncoming = incomingFriendRequests.count
            let afterSent = sentFriendRequests.count
            print("[FRIEND_REQUESTS] \(action.rawValue) requestId=\(requestId). Incoming: \(beforeIncoming)->\(afterIncoming), Sent: \(beforeSent)->\(afterSent)")
            NotificationCenter.default.post(name: .friendRequestsDidChange, object: nil)
            
            // If accepted, refresh friends and friend-requests globally so other views update immediately
            if action == .accept {
                Task {
                    await AppCache.shared.refreshFriends()
                    await AppCache.shared.forceRefreshAllFriendRequests()
                    NotificationCenter.default.post(name: .friendsDidChange, object: nil)
                }
            }
            
        } catch {
            errorMessage = "Failed to \(action == .accept ? "accept" : action == .cancel ? "cancel" : "decline") friend request: \(error.localizedDescription)"
            
            if MockAPIService.isMocking {
                self.incomingFriendRequests.removeAll { $0.id == requestId }
                self.sentFriendRequests.removeAll { $0.id == requestId }
                
                // Update the cache for mock environment too
                appCache.updateFriendRequestsForUser(self.incomingFriendRequests, userId: userId)
                appCache.updateSentFriendRequestsForUser(self.sentFriendRequests, userId: userId)
                
                errorMessage = ""
            }
        }
    }
}
