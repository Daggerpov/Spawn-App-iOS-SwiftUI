//
//  FriendRequestsViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-17.
//

import Combine
import Foundation

class FriendRequestsViewModel: ObservableObject {
	@Published var incomingFriendRequests: [FetchFriendRequestDTO] = []
	@Published var sentFriendRequests: [FetchSentFriendRequestDTO] = []
	@Published var isLoading: Bool = false
	@Published var errorMessage: String = ""

	private var apiService: IAPIService  // Still needed for write operations
	private let userId: UUID
	private var dataService: DataService
	private var appCache: AppCache
	private var cancellables = Set<AnyCancellable>()

	init(userId: UUID, apiService: IAPIService = MockAPIService.isMocking ? MockAPIService() : APIService()) {
		self.userId = userId
		self.apiService = apiService
		self.dataService = DataService.shared
		self.appCache = AppCache.shared

		// Removed AppCache subscriptions to ensure API results drive UI state for friend requests

		// Initialize cache with mock data if in mock mode and cache is empty
		if MockAPIService.isMocking {
			initializeMockDataInCache()
		}
	}

	// MARK: - Helper Methods

	/// Normalizes friend requests by filtering out zero UUIDs and deduplicating by ID
	private func normalizeRequests<T: Identifiable>(_ items: [T]) -> [T] where T.ID == UUID {
		let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
		var seen = Set<UUID>()
		var result: [T] = []
		for item in items where item.id != zeroUUID {
			if !seen.contains(item.id) {
				seen.insert(item.id)
				result.append(item)
			}
		}
		return result
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

		// Fetch both incoming and sent requests in parallel using DataService
		async let incomingResult = dataService.readFriendRequests(
			userId: userId,
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)
		async let sentResult = dataService.readSentFriendRequests(
			userId: userId,
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		let (incomingFetch, sentFetch) = await (incomingResult, sentResult)

		// Handle incoming requests
		switch incomingFetch {
		case .success(let requests, _):
			let normalized = normalizeRequests(requests)
			self.incomingFriendRequests = normalized

			// Fallback to cache if API returned empty but cache has data
			if self.incomingFriendRequests.isEmpty {
				let cachedIncoming = appCache.getCurrentUserFriendRequests()
				if !cachedIncoming.isEmpty { self.incomingFriendRequests = cachedIncoming }
			}

		case .failure(let error):
			errorMessage = ErrorFormattingService.shared.formatError(error)
			if MockAPIService.isMocking {
				self.incomingFriendRequests = FetchFriendRequestDTO.mockFriendRequests
			} else {
				let cachedIncoming = appCache.getCurrentUserFriendRequests()
				self.incomingFriendRequests = cachedIncoming
			}
		}

		// Handle sent requests
		switch sentFetch {
		case .success(let requests, _):
			let normalized = normalizeRequests(requests)
			self.sentFriendRequests = normalized

			// Fallback to cache if API returned empty but cache has data
			if self.sentFriendRequests.isEmpty {
				let cachedSent = appCache.getCurrentUserSentFriendRequests()
				if !cachedSent.isEmpty { self.sentFriendRequests = cachedSent }
			}

		case .failure(let error):
			errorMessage = ErrorFormattingService.shared.formatError(error)
			if MockAPIService.isMocking {
				self.sentFriendRequests = FetchSentFriendRequestDTO.mockSentFriendRequests
			} else {
				let cachedSent = appCache.getCurrentUserSentFriendRequests()
				self.sentFriendRequests = cachedSent
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
		print(
			"[FRIEND_REQUESTS] \(action.rawValue) requestId=\(requestId). Incoming: \(beforeIncoming)->\(afterIncoming), Sent: \(beforeSent)->\(afterSent)"
		)
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

		} catch let error as APIError {
			errorMessage = ErrorFormattingService.shared.formatAPIError(error)

			if MockAPIService.isMocking {
				// In mock mode, the removal already happened above, so just clear error
				errorMessage = ""
			} else {
				// For real API failures, revert the optimistic update by re-fetching
				await fetchFriendRequests()
			}
		} catch {
			errorMessage = ErrorFormattingService.shared.formatError(error)

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
