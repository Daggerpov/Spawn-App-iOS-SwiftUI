//
//  FriendsTabViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Combine
import Foundation
import SwiftUI

class FriendsTabViewModel: ObservableObject {
	@Published var incomingFriendRequests: [FetchFriendRequestDTO] = []
	@Published var outgoingFriendRequests: [FetchSentFriendRequestDTO] = []
	@Published var recommendedFriends: [RecommendedFriendUserDTO] = []
	@Published var friends: [FullFriendUserDTO] = []
	@Published var filteredFriends: [FullFriendUserDTO] = []
	@Published var filteredRecommendedFriends: [RecommendedFriendUserDTO] = []
	@Published var filteredIncomingFriendRequests: [FetchFriendRequestDTO] = []
	@Published var filteredOutgoingFriendRequests: [FetchSentFriendRequestDTO] = []
	@Published var isSearching: Bool = false
	@Published var searchQuery: String = ""
	@Published var isLoading: Bool = false

	@Published var recentlySpawnedWith: [RecentlySpawnedUserDTO] = []
	@Published var searchResults: [BaseUserDTO] = []

	@Published var friendRequestCreationMessage: String = ""
	@Published var createdFriendRequest: FetchFriendRequestDTO?

	var userId: UUID
	private var dataService: DataService
	private var cancellables = Set<AnyCancellable>()
	private var appCache: AppCache  // Keep for cache subscriptions (reactive updates)
	private var notificationObservers: [NSObjectProtocol] = []
	private var apiService: IAPIService  // Keep for dynamic search operations (query-based, not cacheable)

	init(userId: UUID, apiService: IAPIService) {
		self.userId = userId
		self.apiService = apiService  // Still needed for search/filter endpoints
		self.dataService = DataService.shared
		self.appCache = AppCache.shared

		// FriendsTabViewModel init

		if !MockAPIService.isMocking {

			// Subscribe to AppCache friends updates
			appCache.friendsPublisher
				.receive(on: DispatchQueue.main)
				.sink { [weak self] cachedFriends in
					guard let self = self else { return }
					let userFriends = cachedFriends[self.userId] ?? []
					self.friends = userFriends
					if !self.isSearching {
						self.filteredFriends = userFriends
					}
				}
				.store(in: &cancellables)

			// Subscribe to AppCache recommended friends updates
			appCache.recommendedFriendsPublisher
				.receive(on: DispatchQueue.main)
				.sink { [weak self] cachedRecommendedFriends in
					guard let self = self else { return }
					let userRecommendedFriends = cachedRecommendedFriends[self.userId] ?? []
					self.recommendedFriends = userRecommendedFriends
					if !self.isSearching {
						self.filteredRecommendedFriends = userRecommendedFriends
					}
				}
				.store(in: &cancellables)

			// Removed AppCache subscriptions for friend requests and sent friend requests to prevent cache from overriding API results
		}

		// Listen for friend-related changes to keep this tab in sync
		let friendRequestsObserver = NotificationCenter.default.addObserver(
			forName: .friendRequestsDidChange, object: nil, queue: .main
		) { [weak self] _ in
			guard let self = self else { return }
			Task {
				await self.fetchIncomingFriendRequests()
				await self.fetchOutgoingFriendRequests()
			}
		}
		notificationObservers.append(friendRequestsObserver)

		let friendsObserver = NotificationCenter.default.addObserver(
			forName: .friendsDidChange, object: nil, queue: .main
		) { [weak self] _ in
			guard let self = self else { return }
			Task { await self.fetchFriends() }
		}
		notificationObservers.append(friendsObserver)
	}

	deinit {
		print("🧹 [VM] FriendsTabViewModel deinit - cleaning up observers")
		// Remove all notification observers to prevent memory leaks and blocking
		for observer in notificationObservers {
			NotificationCenter.default.removeObserver(observer)
		}
		notificationObservers.removeAll()
	}

	// Call this method to connect the search view model to this view model
	func connectSearchViewModel(_ searchViewModel: SearchViewModel) {
		searchViewModel.$debouncedSearchText
			.sink { [weak self] query in
				self?.searchQuery = query
				if query.isEmpty {
					self?.isSearching = false
					self?.filteredFriends = self?.friends ?? []
					self?.filteredRecommendedFriends = self?.recommendedFriends ?? []
					self?.filteredIncomingFriendRequests = self?.incomingFriendRequests ?? []
					self?.filteredOutgoingFriendRequests = self?.outgoingFriendRequests ?? []
					self?.searchResults = []
				} else {
					self?.isSearching = true
					Task {
						// For friend search, we want to filter existing friends/recommended friends
						await self?.fetchFilteredResults(query: query)
						// For general user search, we want to search all users (run after filtered results)
						await self?.performSearch(searchText: query)
					}
				}
			}
			.store(in: &cancellables)
	}

	func fetchFilteredResults(query: String) async {
		if query.isEmpty {
			await MainActor.run {
				self.filteredFriends = self.friends
				self.filteredRecommendedFriends = self.recommendedFriends
				self.filteredIncomingFriendRequests = self.incomingFriendRequests
				self.filteredOutgoingFriendRequests = self.outgoingFriendRequests
			}
			return
		}

		await MainActor.run {
			isLoading = true
		}

		// Use the backend's filtered endpoint
		if let url = URL(
			string: APIService.baseURL
				+ "users/filtered/\(userId)?searchQuery=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
		) {
			do {
				let searchedUserResult: SearchedUserResult = try await self.apiService.fetchData(
					from: url, parameters: nil)

				await MainActor.run {
					// Parse the unified results and separate by relationship type
					self.filteredIncomingFriendRequests = searchedUserResult.users
						.filter { $0.relationshipType == UserRelationshipType.incomingFriendRequest }
						.compactMap { result in
							guard let friendRequestId = result.friendRequestId else { return nil }
							return FetchFriendRequestDTO(id: friendRequestId, senderUser: result.user)
						}

					self.filteredOutgoingFriendRequests = searchedUserResult.users
						.filter { $0.relationshipType == UserRelationshipType.outgoingFriendRequest }
						.compactMap { result in
							guard let friendRequestId = result.friendRequestId else { return nil }
							// For outgoing requests, the user in the result is the receiver
							return FetchSentFriendRequestDTO(id: friendRequestId, receiverUser: result.user)
						}

					self.filteredRecommendedFriends = searchedUserResult.users
						.filter { $0.relationshipType == UserRelationshipType.recommendedFriend }
						.map { result in
							RecommendedFriendUserDTO(
								id: result.user.id,
								username: result.user.username,
								profilePicture: result.user.profilePicture,
								name: result.user.name,
								bio: result.user.bio,
								email: result.user.email,
								mutualFriendCount: result.mutualFriendCount ?? 0
							)
						}

					self.filteredFriends = searchedUserResult.users
						.filter { $0.relationshipType == UserRelationshipType.friend }
						.map { result in
							FullFriendUserDTO(
								id: result.user.id,
								username: result.user.username,
								profilePicture: result.user.profilePicture,
								name: result.user.name,
								bio: result.user.bio,
								email: result.user.email
							)
						}

					self.isLoading = false
				}
			} catch let error as APIError {
				print("Error fetching filtered results: \(ErrorFormattingService.shared.formatAPIError(error))")
				// Fallback to local filtering if the API call fails
				await localFilterResults(query: query)
				await MainActor.run {
					self.isLoading = false
				}
			} catch {
				print("Error fetching filtered results: \(ErrorFormattingService.shared.formatError(error))")
				// Fallback to local filtering if the API call fails
				await localFilterResults(query: query)
				await MainActor.run {
					self.isLoading = false
				}
			}
		} else {
			print("Invalid URL for filtered search")
			await localFilterResults(query: query)
			await MainActor.run {
				self.isLoading = false
			}
		}
	}

	// MARK: - Helper Methods

	/// Checks if a user matches a search query
	private func userMatches(name: String?, username: String?, query: String) -> Bool {
		let lowercaseQuery = query.lowercased()
		let lowercasedName = name?.lowercased() ?? ""
		let lowercasedUsername = username?.lowercased() ?? ""
		return lowercasedName.contains(lowercaseQuery) || lowercasedUsername.contains(lowercaseQuery)
	}

	// Local fallback filtering in case the API call fails
	private func localFilterResults(query: String) async {
		await MainActor.run {
			self.filteredFriends = self.friends.filter { friend in
				userMatches(name: friend.name, username: friend.username, query: query)
			}

			self.filteredRecommendedFriends = self.recommendedFriends.filter { friend in
				userMatches(name: friend.name, username: friend.username, query: query)
			}

			self.filteredIncomingFriendRequests = self.incomingFriendRequests.filter { request in
				let friend = request.senderUser
				return userMatches(name: friend.name, username: friend.username, query: query)
			}

			self.filteredOutgoingFriendRequests = self.outgoingFriendRequests.filter { request in
				let friend = request.receiverUser
				return userMatches(name: friend.name, username: friend.username, query: query)
			}
		}
	}

	// Remove friend from recommended list after adding
	@MainActor
	func removeFromRecommended(friendId: UUID) {
		recommendedFriends.removeAll { $0.id == friendId }
		filteredRecommendedFriends.removeAll { $0.id == friendId }
		// Update cache to reflect the change
		appCache.updateRecommendedFriendsForUser(recommendedFriends, userId: userId)
	}

	// Remove user from recently spawned with list after adding
	@MainActor
	func removeFromRecentlySpawnedWith(userId: UUID) {
		recentlySpawnedWith.removeAll { $0.user.id == userId }
	}

	// Remove user from search results after adding
	@MainActor
	func removeFromSearchResults(userId: UUID) {
		searchResults.removeAll { $0.id == userId }
	}

	// Method to get cached recommended friends for passing to other views
	func getCachedRecommendedFriends() -> [RecommendedFriendUserDTO] {
		return appCache.getCurrentUserRecommendedFriends()
	}

	// Method to refresh recommended friends cache
	func refreshRecommendedFriendsCache() async {
		await fetchRecommendedFriends()
	}

	/// Loads cached friends data immediately (synchronous, fast, non-blocking)
	/// Call this before fetchAllData() to show cached data instantly
	@MainActor
	func loadCachedData() {
		let cachedFriends = appCache.getCurrentUserFriends()
		let cachedRecommendedFriends = appCache.getCurrentUserRecommendedFriends()
		let cachedIncomingRequests = appCache.getCurrentUserFriendRequests()
		let cachedOutgoingRequests = appCache.getCurrentUserSentFriendRequests()

		if !cachedFriends.isEmpty {
			self.friends = cachedFriends
		}
		if !cachedRecommendedFriends.isEmpty {
			self.recommendedFriends = cachedRecommendedFriends
		}
		if !cachedIncomingRequests.isEmpty {
			self.incomingFriendRequests = cachedIncomingRequests
		}
		if !cachedOutgoingRequests.isEmpty {
			self.outgoingFriendRequests = cachedOutgoingRequests
		}

		// Initialize filtered lists
		self.filteredFriends = self.friends
		self.filteredRecommendedFriends = self.recommendedFriends
		self.filteredIncomingFriendRequests = self.incomingFriendRequests
		self.filteredOutgoingFriendRequests = self.outgoingFriendRequests

		if cachedFriends.isEmpty && cachedRecommendedFriends.isEmpty && cachedIncomingRequests.isEmpty
			&& cachedOutgoingRequests.isEmpty
		{
			print("⚠️ FriendsTabViewModel: No cached data available")
		}
	}

	func fetchAllData() async {
		print("🔄 [VM] FriendsTabViewModel.fetchAllData started")
		let startTime = Date()

		// Check cache first - only show loading if we need to fetch from API
		let cachedFriends = appCache.getCurrentUserFriends()
		let cachedRecommendedFriends = appCache.getCurrentUserRecommendedFriends()
		let cachedIncomingRequests = appCache.getCurrentUserFriendRequests()
		let cachedOutgoingRequests = appCache.getCurrentUserSentFriendRequests()

		let hasCachedData =
			!cachedFriends.isEmpty || !cachedRecommendedFriends.isEmpty || !cachedIncomingRequests.isEmpty
			|| !cachedOutgoingRequests.isEmpty

		if hasCachedData {
			// Load cached data immediately - no loading state needed
			await MainActor.run {
				if !cachedFriends.isEmpty {
					self.friends = cachedFriends
					print("   Applied \(cachedFriends.count) friends from cache")
				}
				if !cachedRecommendedFriends.isEmpty {
					self.recommendedFriends = cachedRecommendedFriends
					print("   Applied \(cachedRecommendedFriends.count) recommended friends from cache")
				}
				if !cachedIncomingRequests.isEmpty {
					self.incomingFriendRequests = cachedIncomingRequests
					print("   Applied \(cachedIncomingRequests.count) incoming requests from cache")
				}
				if !cachedOutgoingRequests.isEmpty {
					self.outgoingFriendRequests = cachedOutgoingRequests
					print("   Applied \(cachedOutgoingRequests.count) outgoing requests from cache")
				}

				// Initialize filtered lists
				self.filteredFriends = self.friends
				self.filteredRecommendedFriends = self.recommendedFriends
				self.filteredIncomingFriendRequests = self.incomingFriendRequests
				self.filteredOutgoingFriendRequests = self.outgoingFriendRequests
			}

			// Refresh profile pictures for all visible users in background (non-blocking)
			Task.detached(priority: .background) {
				await self.refreshProfilePictures()
			}

			let duration = Date().timeIntervalSince(startTime)
			print("⏱️ [VM] fetchAllData (cached) completed in \(String(format: "%.3f", duration))s")
			return
		}

		print("⚠️ [VM] No cached data - fetching from API with loading state")
		// No cached data - show loading and fetch from API
		await MainActor.run {
			isLoading = true
		}

		// Create a task group to run these in parallel
		await withTaskGroup(of: Void.self) { group in
			group.addTask {
				await self.fetchIncomingFriendRequests()
			}
			group.addTask {
				await self.fetchOutgoingFriendRequests()
			}
			group.addTask {
				await self.fetchRecommendedFriends()
			}
			group.addTask {
				await self.fetchFriends()
			}
			group.addTask {
				await self.fetchRecentlySpawnedWith()
			}
		}

		// Initialize filtered lists with full lists after fetching
		await MainActor.run {

			self.filteredFriends = self.friends
			self.filteredRecommendedFriends = self.recommendedFriends
			self.filteredIncomingFriendRequests = self.incomingFriendRequests
			self.filteredOutgoingFriendRequests = self.outgoingFriendRequests
			self.isLoading = false
		}

		// Refresh profile pictures for all visible users in background (non-blocking)
		Task.detached(priority: .background) {
			await self.refreshProfilePictures()
		}

		let duration = Date().timeIntervalSince(startTime)
		print("⏱️ [VM] fetchAllData (from API) completed in \(String(format: "%.2f", duration))s")
		print("   Fetched: \(friends.count) friends, \(recommendedFriends.count) recommended")
		print("   Requests: \(incomingFriendRequests.count) incoming, \(outgoingFriendRequests.count) outgoing")
	}

	internal func fetchIncomingFriendRequests() async {
		let result: DataResult<[FetchFriendRequestDTO]> = await dataService.read(
			.friendRequests(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let requests, _):
			// Normalize: filter zero UUIDs and de-duplicate by id
			let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
			var seen = Set<UUID>()
			let normalized = requests.compactMap { req -> FetchFriendRequestDTO? in
				guard req.id != zeroUUID else { return nil }
				if seen.contains(req.id) { return nil }
				seen.insert(req.id)
				return req
			}

			await MainActor.run {
				self.incomingFriendRequests = normalized
			}

		case .failure:
			await MainActor.run {
				self.incomingFriendRequests = []
			}
		}
	}

	internal func fetchOutgoingFriendRequests() async {
		let result: DataResult<[FetchSentFriendRequestDTO]> = await dataService.read(
			.sentFriendRequests(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let requests, _):
			// Normalize: filter zero UUIDs and de-duplicate by id
			let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
			var seen = Set<UUID>()
			let normalized = requests.compactMap { req -> FetchSentFriendRequestDTO? in
				guard req.id != zeroUUID else { return nil }
				if seen.contains(req.id) { return nil }
				seen.insert(req.id)
				return req
			}

			await MainActor.run {
				self.outgoingFriendRequests = normalized
			}

		case .failure:
			await MainActor.run {
				self.outgoingFriendRequests = []
			}
		}
	}

	internal func fetchRecommendedFriends() async {
		let result: DataResult<[RecommendedFriendUserDTO]> = await dataService.read(
			.recommendedFriends(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let friends, _):
			await MainActor.run {
				self.recommendedFriends = friends
			}

		case .failure:
			await MainActor.run {
				self.recommendedFriends = []
			}
		}
	}

	func fetchFriends() async {
		let result: DataResult<[FullFriendUserDTO]> = await dataService.read(
			.friends(userId: userId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let friends, _):
			await MainActor.run {
				self.friends = friends
			}

		case .failure:
			await MainActor.run {
				self.friends = []
			}
		}
	}

	func addFriend(friendUserId: UUID) async {
		await MainActor.run {
			isLoading = true
		}

		let createdFriendRequest = CreateFriendRequestDTO(
			id: UUID(),
			senderUserId: userId,
			receiverUserId: friendUserId
		)

		// Use DataService with WriteOperationType
		let operationType = WriteOperationType.sendFriendRequest(request: createdFriendRequest)
		let result: DataResult<CreateFriendRequestDTO> = await dataService.write(
			operationType, body: createdFriendRequest)

		switch result {
		case .success:
			// Only refresh outgoing friend requests to show the new request
			// Don't refresh recommended friends - let the view handle the removal animation
			await fetchOutgoingFriendRequests()

			// Ensure loading state is cleared
			await MainActor.run {
				isLoading = false
			}

		case .failure(let error):
			await MainActor.run {
				friendRequestCreationMessage = ErrorFormattingService.shared.formatError(error)
				isLoading = false
			}
		}
	}

	/// Refresh profile pictures for all users visible in the friends tab
	func refreshProfilePictures() async {
		print("🔄 [FriendsTabViewModel] Refreshing profile pictures for friends tab users")
		let profilePictureCache = ProfilePictureCache.shared

		var usersToRefresh: [(userId: UUID, profilePictureUrl: String?)] = []

		// Add friends
		for friend in friends {
			usersToRefresh.append((userId: friend.id, profilePictureUrl: friend.profilePicture))
		}

		// Add recommended friends
		for recommendedFriend in recommendedFriends {
			usersToRefresh.append((userId: recommendedFriend.id, profilePictureUrl: recommendedFriend.profilePicture))
		}

		// Add incoming friend request senders
		for request in incomingFriendRequests {
			usersToRefresh.append((userId: request.senderUser.id, profilePictureUrl: request.senderUser.profilePicture))
		}

		// Add outgoing friend request receivers
		for request in outgoingFriendRequests {
			usersToRefresh.append(
				(userId: request.receiverUser.id, profilePictureUrl: request.receiverUser.profilePicture))
		}

		// Remove duplicates
		var seen = Set<UUID>()
		let uniqueUsers = usersToRefresh.compactMap { user -> (userId: UUID, profilePictureUrl: String?)? in
			guard !seen.contains(user.userId) else { return nil }
			seen.insert(user.userId)
			return user
		}

		print("🔄 [FriendsTabViewModel] Found \(uniqueUsers.count) users to refresh profile pictures for")

		// Refresh stale profile pictures
		await profilePictureCache.refreshStaleProfilePictures(for: uniqueUsers)
	}

	func removeFriend(friendUserId: UUID) async {
		await MainActor.run {
			isLoading = true
		}

		// Use DataService with WriteOperationType
		let operationType = WriteOperationType.removeFriend(currentUserId: userId, friendId: friendUserId)
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(operationType)

		switch result {
		case .success:
			// Remove from local arrays and refresh data
			await MainActor.run {
				self.friends.removeAll { $0.id == friendUserId }
				self.filteredFriends.removeAll { $0.id == friendUserId }
			}
			// Refresh friends from API to update cache
			let _: DataResult<[FullFriendUserDTO]> = await dataService.read(
				.friends(userId: userId), cachePolicy: .apiOnly)

		case .failure(let error):
			print("Error removing friend: \(ErrorFormattingService.shared.formatError(error))")
		}

		await MainActor.run {
			isLoading = false
		}
	}

	func fetchRecentlySpawnedWith() async {
		// Check if user is still authenticated before making API call
		guard UserAuthViewModel.shared.spawnUser != nil, UserAuthViewModel.shared.isLoggedIn else {
			print("Cannot fetch recently spawned users: User is not logged in")
			await MainActor.run {
				self.isLoading = false
			}
			return
		}

		await MainActor.run {
			isLoading = true
		}

		do {
			// API endpoint for getting recently spawned with users
			guard let url = URL(string: APIService.baseURL + "users/\(userId)/recent-users") else {
				await MainActor.run {
					isLoading = false
				}
				return
			}

			let fetchedUsers: [RecentlySpawnedUserDTO] = try await apiService.fetchData(from: url, parameters: nil)

			await MainActor.run {
				self.recentlySpawnedWith = fetchedUsers
				self.isLoading = false
			}
		} catch let error as APIError {
			print("Error fetching recently spawned users: \(ErrorFormattingService.shared.formatAPIError(error))")
			// If API fails, use empty array
			await MainActor.run {
				self.recentlySpawnedWith = []
				self.isLoading = false
			}
		} catch {
			print("Error fetching recently spawned users: \(ErrorFormattingService.shared.formatError(error))")
			// If API fails, use empty array
			await MainActor.run {
				self.recentlySpawnedWith = []
				self.isLoading = false
			}
		}
	}

	private func performSearch(searchText: String) async {
		if searchText.isEmpty {
			await MainActor.run {
				searchResults = []
			}
			return
		}

		// Don't set isLoading here as it's already set in the search flow

		if MockAPIService.isMocking {
			// Filter mock data for testing
			let lowercasedSearchText = searchText.lowercased()
			let filteredResults = BaseUserDTO.mockUsers.filter { user in
				let name = FormatterService.shared.formatName(user: user).lowercased()
				let username = (user.username ?? "").lowercased()

				return name.contains(lowercasedSearchText) || username.contains(lowercasedSearchText)
			}
			await MainActor.run {
				searchResults = filteredResults
			}
			return
		}

		do {
			// API endpoint for searching users: /api/v1/users/search?searchQuery={searchText}
			guard let url = URL(string: APIService.baseURL + "users/search") else {
				print("Invalid URL for user search")
				await MainActor.run {
					searchResults = []
				}
				return
			}

			let fetchedUsers: [BaseUserDTO] = try await apiService.fetchData(
				from: url,
				parameters: [
					"searchQuery": searchText,
					"requestingUserId": userId.uuidString,
				]
			)

			// Ensure updating on the main thread
			await MainActor.run {
				self.searchResults = fetchedUsers
			}
		} catch let error as APIError {
			print("Error performing user search: \(ErrorFormattingService.shared.formatAPIError(error))")
			await MainActor.run {
				self.searchResults = []
			}
		} catch {
			print("Error performing user search: \(ErrorFormattingService.shared.formatError(error))")
			await MainActor.run {
				self.searchResults = []
			}
		}
	}

	// Method to check if a user is already a friend
	func isFriend(userId: UUID) -> Bool {
		return friends.contains { $0.id == userId }
	}

	// MARK: - Profile Sharing

	/// Copy profile URL to clipboard
	func copyProfileURL(for user: Nameable) {
		ServiceConstants.generateProfileShareCodeURL(for: user.id) { profileURL in
			let url = profileURL ?? ServiceConstants.generateProfileShareURL(for: user.id)

			// Clear the pasteboard first to avoid any contamination
			UIPasteboard.general.items = []

			// Set only the URL string to the pasteboard
			UIPasteboard.general.string = url.absoluteString

			// Show notification toast
			DispatchQueue.main.async {
				InAppNotificationManager.shared.showNotification(
					title: "Link copied to clipboard",
					message: "Profile link has been copied to your clipboard",
					type: .success,
					duration: 5.0
				)
			}
		}
	}

	/// Share profile using the system share sheet
	func shareProfile(for user: Nameable, from viewController: UIViewController? = nil) {
		ServiceConstants.generateProfileShareCodeURL(for: user.id) { profileURL in
			let url = profileURL ?? ServiceConstants.generateProfileShareURL(for: user.id)
			let shareText =
				"Check out \(FormatterService.shared.formatName(user: user))'s profile on Spawn! \(url.absoluteString)"

			let activityViewController = UIActivityViewController(
				activityItems: [shareText],
				applicationActivities: nil
			)

			// Present the activity view controller
			if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
				let window = windowScene.windows.first
			{

				var topController = window.rootViewController
				while let presentedViewController = topController?.presentedViewController {
					topController = presentedViewController
				}

				if let popover = activityViewController.popoverPresentationController {
					popover.sourceView = topController?.view
					popover.sourceRect = topController?.view.bounds ?? CGRect.zero
				}

				topController?.present(activityViewController, animated: true, completion: nil)
			}
		}
	}

	// MARK: - User Management

	/// Block a user
	func blockUser(blockerId: UUID, blockedId: UUID, reason: String) async {
		// Use DataService with WriteOperationType
		let operationType = WriteOperationType.blockUser(blockerId: blockerId, blockedId: blockedId, reason: reason)
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(operationType)

		switch result {
		case .success:
			// Refresh friends from API to update cache
			let _: DataResult<[FullFriendUserDTO]> = await dataService.read(
				.friends(userId: blockerId), cachePolicy: .apiOnly)

			// Remove the blocked user from local friends list immediately
			await MainActor.run {
				self.friends.removeAll { $0.id == blockedId }
				self.filteredFriends.removeAll { $0.id == blockedId }
			}

		case .failure(let error):
			print("Failed to block user: \(ErrorFormattingService.shared.formatError(error))")
		}
	}

	/// Remove a friend and refresh data
	func removeFriendAndRefresh(currentUserId: UUID, friendUserId: UUID) async {
		// Use the existing removeFriend method which already handles API calls and cache updates
		await removeFriend(friendUserId: friendUserId)

		// Refresh data to ensure UI is updated
		await fetchAllData()
	}
}
