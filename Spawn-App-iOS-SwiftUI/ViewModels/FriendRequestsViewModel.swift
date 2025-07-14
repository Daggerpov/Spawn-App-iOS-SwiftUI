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
        
        if MockAPIService.isMocking {
            self.incomingFriendRequests = FetchFriendRequestDTO.mockFriendRequests
            self.sentFriendRequests = FetchFriendRequestDTO.mockSentFriendRequests
        } else {
            // Subscribe to cache updates for this user's friend requests
            appCache.$friendRequests
                .sink { [weak self] cachedFriendRequests in
                    guard let self = self else { return }
                    let userFriendRequests = cachedFriendRequests[self.userId] ?? []
                    self.incomingFriendRequests = userFriendRequests
                }
                .store(in: &cancellables)
        }
    }
    
    @MainActor
    func fetchFriendRequests() async {
        isLoading = true
        defer { isLoading = false }
        
        // Check cache first for incoming requests
        let cachedIncoming = appCache.getCurrentUserFriendRequests()
        if !cachedIncoming.isEmpty {
            self.incomingFriendRequests = cachedIncoming
        }
        
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
            
            // Update cache for incoming requests
            appCache.updateFriendRequestsForUser(fetchedIncomingRequests, userId: userId)
            
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
            
        } catch {
            errorMessage = "Failed to \(action == .accept ? "accept" : action == .cancel ? "cancel" : "decline") friend request: \(error.localizedDescription)"
            
            // For mock environment, simulate success
            if MockAPIService.isMocking {
                self.incomingFriendRequests.removeAll { $0.id == requestId }
                self.sentFriendRequests.removeAll { $0.id == requestId }
                
                // Update the cache for mock environment too
                appCache.updateFriendRequestsForUser(self.incomingFriendRequests, userId: userId)
            }
        }
    }
}

