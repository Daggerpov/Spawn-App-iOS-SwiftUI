//
//  FriendRequestsViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-17.
//

import Foundation

@Observable
@MainActor
final class FriendRequestsViewModel {
	var incomingFriendRequests: [FetchFriendRequestDTO] = []
	var sentFriendRequests: [FetchSentFriendRequestDTO] = []
	var isLoading: Bool = false
	var errorMessage: String = ""

	private let userId: UUID
	private var dataService: DataService
	private let notificationService = InAppNotificationService.shared

	init(userId: UUID, dataService: DataService? = nil) {
		self.userId = userId
		self.dataService = dataService ?? DataService.shared
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

	func fetchFriendRequests() async {
		isLoading = true
		defer { isLoading = false }

		// Fetch both incoming and sent requests in parallel using DataService
		async let incomingResult: DataResult<[FetchFriendRequestDTO]> = dataService.read(
			.friendRequests(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)
		async let sentResult: DataResult<[FetchSentFriendRequestDTO]> = dataService.read(
			.sentFriendRequests(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		let (incomingFetch, sentFetch) = await (incomingResult, sentResult)

		// Handle incoming requests
		switch incomingFetch {
		case .success(let requests, _):
			let normalized = normalizeRequests(requests)
			self.incomingFriendRequests = normalized

		case .failure(let error):
			errorMessage = notificationService.handleError(
				error, resource: .friendRequest, operation: .fetch)
			self.incomingFriendRequests = []
		}

		// Handle sent requests
		switch sentFetch {
		case .success(let requests, _):
			let normalized = normalizeRequests(requests)
			self.sentFriendRequests = normalized

		case .failure(let error):
			// Don't show duplicate notification for same fetch operation
			errorMessage = notificationService.handleError(
				error, resource: .friendRequest, operation: .fetch, showNotification: false)
			self.sentFriendRequests = []
		}
	}

	func respondToFriendRequest(requestId: UUID, action: FriendRequestAction) async {
		let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
		if requestId == zeroUUID { return }

		let beforeIncoming = incomingFriendRequests.count
		let beforeSent = sentFriendRequests.count

		// IMMEDIATELY remove the request from UI to provide instant feedback
		self.incomingFriendRequests.removeAll { $0.id == requestId }
		self.sentFriendRequests.removeAll { $0.id == requestId }

		let afterIncoming = incomingFriendRequests.count
		let afterSent = sentFriendRequests.count
		print(
			"[FRIEND_REQUESTS] \(action.rawValue) requestId=\(requestId). Incoming: \(beforeIncoming)->\(afterIncoming), Sent: \(beforeSent)->\(afterSent)"
		)
		NotificationCenter.default.post(name: .friendRequestsDidChange, object: nil)

		// Use DataService with WriteOperationType
		let result: DataResult<EmptyResponse>

		if action == .cancel {
			// Delete operation (cancel sent request)
			let operation = WriteOperation<EmptyRequestBody>.delete(
				endpoint: "friend-requests/\(requestId)",
				cacheInvalidationKeys: ["friendRequests-\(userId)", "sentFriendRequests-\(userId)"]
			)
			result = await dataService.writeWithoutResponse(operation)
		} else {
			// PUT operation (accept or reject)
			let operationType: WriteOperationType =
				action == .accept
				? .acceptFriendRequest(requestId: requestId)
				: .declineFriendRequest(requestId: requestId)

			result = await dataService.writeWithoutResponse(operationType)
		}

		switch result {
		case .success:
			// If accepted, refresh friends and friend-requests globally so other views update immediately
			if action == .accept {
				// Refresh data to update caches
				let _: DataResult<[FullFriendUserDTO]> = await dataService.read(
					.friends(userId: userId), cachePolicy: .apiOnly)
				let _: DataResult<[FetchFriendRequestDTO]> = await dataService.read(
					.friendRequests(userId: userId), cachePolicy: .apiOnly)
				NotificationCenter.default.post(name: .friendsDidChange, object: nil)
			}

		case .failure(let error):
			// Determine the operation type for better error messages
			let operation: OperationContext
			switch action {
			case .accept:
				operation = .accept
			case .decline:
				operation = .reject
			case .cancel:
				operation = .delete
			}
			errorMessage = notificationService.handleError(
				error, resource: .friendRequest, operation: operation)
			// For real API failures, revert the optimistic update by re-fetching
			await fetchFriendRequests()
		}
	}
}
