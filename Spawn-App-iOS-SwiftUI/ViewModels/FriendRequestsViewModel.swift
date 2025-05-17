//
//  FriendRequestsViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-17.
//

import Foundation
import Combine

class FriendRequestsViewModel: ObservableObject {
    @Published var friendRequests: [FetchFriendRequestDTO] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private var apiService: IAPIService
    private let userId: UUID
    
    init(userId: UUID, apiService: IAPIService = MockAPIService.isMocking ? MockAPIService() : APIService()) {
        self.userId = userId
        self.apiService = apiService
        
        if MockAPIService.isMocking {
            self.friendRequests = FetchFriendRequestDTO.mockFriendRequests
        }
    }
    
    @MainActor
    func fetchFriendRequests() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Correct API endpoint for getting incoming friend requests: /api/v1/friend-requests/incoming/{userId}
            guard let url = URL(string: APIService.baseURL + "friend-requests/incoming/\(userId)") else {
                errorMessage = "Invalid URL"
                return
            }
            
            let fetchedRequests: [FetchFriendRequestDTO] = try await apiService.fetchData(from: url, parameters: nil)
            self.friendRequests = fetchedRequests
        } catch {
            errorMessage = "Failed to fetch friend requests: \(error.localizedDescription)"
            if !MockAPIService.isMocking {
                // For development, load mock data if real API fails
                self.friendRequests = FetchFriendRequestDTO.mockFriendRequests
            }
        }
    }
    
    @MainActor
    func respondToFriendRequest(requestId: UUID, action: FriendRequestAction) async {
        do {
            // API endpoint: /api/v1/friend-requests/{friendRequestId}?friendRequestAction={accept/reject}
            guard let url = URL(string: APIService.baseURL + "friend-requests/\(requestId)") else {
                errorMessage = "Invalid URL"
                return
            }
            
            let _: EmptyResponse = try await apiService.updateData(
                EmptyRequestBody(),
                to: url,
                parameters: ["friendRequestAction": action.rawValue]
            )
            
            // Remove the request from the list
            self.friendRequests.removeAll { $0.id == requestId }
            
        } catch {
            errorMessage = "Failed to \(action == .accept ? "accept" : "decline") friend request: \(error.localizedDescription)"
            
            // For mock environment, simulate success
            if MockAPIService.isMocking {
                self.friendRequests.removeAll { $0.id == requestId }
            }
        }
    }
}

