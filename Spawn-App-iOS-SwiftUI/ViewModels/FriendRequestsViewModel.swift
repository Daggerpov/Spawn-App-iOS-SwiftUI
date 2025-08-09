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
            
            // Update UI first, then cache
            self.incomingFriendRequests = fetchedIncomingRequests
            self.sentFriendRequests = fetchedSentRequests
            
            // Update cache for both incoming and sent requests
            appCache.updateFriendRequestsForUser(fetchedIncomingRequests, userId: userId)
            appCache.updateSentFriendRequestsForUser(fetchedSentRequests, userId: userId)
            
        } catch {
            errorMessage = "Failed to fetch friend requests: \(error.localizedDescription)"
            if MockAPIService.isMocking {
                // Fallback to mock data in mock environment
                self.incomingFriendRequests = FetchFriendRequestDTO.mockFriendRequests
                self.sentFriendRequests = FetchFriendRequestDTO.mockSentFriendRequests
            } else {
                // Clear lists on failure to avoid showing stale cache
                self.incomingFriendRequests = []
                self.sentFriendRequests = []
            }
        }
    }
    
    @MainActor
    func respondToFriendRequest(requestId: UUID, action: FriendRequestAction) async {
        do {
            // API endpoint: /api/v1/friend-requests/{friendRequestId}?friendRequestAction={accept/reject/cancel}
            guard let url = URL(string: APIService.baseURL + "friend-requests/\(requestId)") else {
                errorMessage = "Invalid URL"
                return
            }
            
            let _: EmptyResponse = try await apiService.updateData(
                EmptyRequestBody(),
                to: url,
                parameters: ["friendRequestAction": action.rawValue]
            )
            
            // Remove the request from both lists (it could be in either)
            self.incomingFriendRequests.removeAll { $0.id == requestId }
            self.sentFriendRequests.removeAll { $0.id == requestId }
            
            // Update the cache with the modified friend requests
            appCache.updateFriendRequestsForUser(self.incomingFriendRequests, userId: userId)
            appCache.updateSentFriendRequestsForUser(self.sentFriendRequests, userId: userId)
            
        } catch {
            errorMessage = "Failed to \(action == .accept ? "accept" : action == .cancel ? "cancel" : "decline") friend request: \(error.localizedDescription)"
            
            if MockAPIService.isMocking {
                self.incomingFriendRequests.removeAll { $0.id == requestId }
                self.sentFriendRequests.removeAll { $0.id == requestId }
                
                // Update the cache for mock environment too
                appCache.updateFriendRequestsForUser(self.incomingFriendRequests, userId: userId)
                appCache.updateSentFriendRequestsForUser(self.sentFriendRequests, userId: userId)
                
                // Clear the error message since the action was successful in mock mode
                errorMessage = ""
            }
        }
    }
}
