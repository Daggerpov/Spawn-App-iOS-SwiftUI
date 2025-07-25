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
        
        // Always subscribe to cache updates for this user's friend requests, regardless of mock mode
        appCache.$friendRequests
            .sink { [weak self] cachedFriendRequests in
                guard let self = self else { return }
                let userFriendRequests = cachedFriendRequests[self.userId] ?? []
                self.incomingFriendRequests = userFriendRequests
            }
            .store(in: &cancellables)
        
        // Always subscribe to cache updates for this user's sent friend requests, regardless of mock mode
        appCache.$sentFriendRequests
            .sink { [weak self] cachedSentFriendRequests in
                guard let self = self else { return }
                let userSentFriendRequests = cachedSentFriendRequests[self.userId] ?? []
                self.sentFriendRequests = userSentFriendRequests
            }
            .store(in: &cancellables)
        
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
        
        // Show cached data immediately if available
        let cachedIncoming = appCache.getCurrentUserFriendRequests()
        let cachedSent = appCache.getCurrentUserSentFriendRequests()
        
        self.incomingFriendRequests = cachedIncoming
        self.sentFriendRequests = cachedSent
        
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
            
            let fetchedIncomingRequests: [FetchFriendRequestDTO] = try await apiService.fetchData(from: incomingUrl, parameters: nil)
            let fetchedSentRequests: [FetchFriendRequestDTO] = try await apiService.fetchData(from: sentUrl, parameters: nil)
            
            self.incomingFriendRequests = fetchedIncomingRequests
            self.sentFriendRequests = fetchedSentRequests
            
            // Update cache for both incoming and sent requests
            appCache.updateFriendRequestsForUser(fetchedIncomingRequests, userId: userId)
            appCache.updateSentFriendRequestsForUser(fetchedSentRequests, userId: userId)
            
        } catch {
            errorMessage = "Failed to fetch friend requests: \(error.localizedDescription)"
            if !MockAPIService.isMocking {
                // For development, load mock data if real API fails
                self.incomingFriendRequests = FetchFriendRequestDTO.mockFriendRequests
                self.sentFriendRequests = FetchFriendRequestDTO.mockSentFriendRequests
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
            
            // For mock environment, simulate success even when the API call "fails"
            // because the MockAPIService will return EmptyResponse() for friend request actions
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
