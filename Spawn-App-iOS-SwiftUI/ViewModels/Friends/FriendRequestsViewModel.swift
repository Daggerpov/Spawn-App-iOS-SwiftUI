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
    @Published var sentFriendRequests: [FetchSentFriendRequestDTO] = []
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
            appCache.updateSentFriendRequestsForUser(FetchSentFriendRequestDTO.mockSentFriendRequests, userId: userId)
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
            async let sent: [FetchSentFriendRequestDTO] = apiService.fetchData(from: sentUrl, parameters: nil)
            
            let (fetchedIncomingRequests, fetchedSentRequests) = try await (incoming, sent)
            
            // Normalize: filter out invalid zero UUIDs and de-duplicate by id
            let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            func normalize(_ items: [FetchFriendRequestDTO]) -> [FetchFriendRequestDTO] {
                var seen = Set<UUID>()
                var result: [FetchFriendRequestDTO] = []
                for item in items where item.id != zeroUUID {
                    if !seen.contains(item.id) {
                        seen.insert(item.id)
                        result.append(item)
                    }
                }
                return result
            }
            
            func normalizeSent(_ items: [FetchSentFriendRequestDTO]) -> [FetchSentFriendRequestDTO] {
                var seen = Set<UUID>()
                var result: [FetchSentFriendRequestDTO] = []
                for item in items where item.id != zeroUUID {
                    if !seen.contains(item.id) {
                        seen.insert(item.id)
                        result.append(item)
                    }
                }
                return result
            }
            
            let normalizedIncoming = normalize(fetchedIncomingRequests)
            let normalizedSent = normalizeSent(fetchedSentRequests)
            
            // Update UI first, then cache
            self.incomingFriendRequests = normalizedIncoming
            self.sentFriendRequests = normalizedSent
            
            // Update cache for both incoming and sent requests
            appCache.updateFriendRequestsForUser(normalizedIncoming, userId: userId)
            appCache.updateSentFriendRequestsForUser(normalizedSent, userId: userId)
            
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
                self.sentFriendRequests = FetchSentFriendRequestDTO.mockSentFriendRequests
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
        
        let beforeIncoming = incomingFriendRequests.count
        let beforeSent = sentFriendRequests.count
        
        // IMMEDIATELY remove the request from UI to provide instant feedback
        self.incomingFriendRequests.removeAll { $0.id == requestId }
        self.sentFriendRequests.removeAll { $0.id == requestId }
        
        // Update the cache immediately with the modified friend requests
        appCache.updateFriendRequestsForUser(self.incomingFriendRequests, userId: userId)
        appCache.updateSentFriendRequestsForUser(self.sentFriendRequests, userId: userId)
        
        let afterIncoming = incomingFriendRequests.count
        let afterSent = sentFriendRequests.count
        print("[FRIEND_REQUESTS] \(action.rawValue) requestId=\(requestId). Incoming: \(beforeIncoming)->\(afterIncoming), Sent: \(beforeSent)->\(afterSent)")
        NotificationCenter.default.post(name: .friendRequestsDidChange, object: nil)
        
        do {
            guard let url = URL(string: APIService.baseURL + "friend-requests/\(requestId)") else {
                errorMessage = "Invalid URL"
                // Revert the UI change if URL is invalid
                await fetchFriendRequests()
                return
            }
            
            if action == .cancel {
                try await apiService.deleteData(from: url, parameters: nil, object: Optional<String>.none)
            } else {
                let _: EmptyResponse = try await apiService.updateData(
                    EmptyRequestBody(),
                    to: url,
                    parameters: ["friendRequestAction": action.rawValue]
                )
            }
            
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
                // In mock mode, the removal already happened above, so just clear error
                errorMessage = ""
            } else {
                // For real API failures, revert the optimistic update by re-fetching
                await fetchFriendRequests()
            }
        }
    }
}
