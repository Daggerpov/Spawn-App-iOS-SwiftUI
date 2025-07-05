//
//  FriendsTabViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation
import Combine

class FriendsTabViewModel: ObservableObject {
	@Published var incomingFriendRequests: [FetchFriendRequestDTO] = []
    @Published var recommendedFriends: [RecommendedFriendUserDTO] = []
	@Published var friends: [FullFriendUserDTO] = []
    @Published var filteredFriends: [FullFriendUserDTO] = []
    @Published var filteredRecommendedFriends: [RecommendedFriendUserDTO] = []
    @Published var filteredIncomingFriendRequests: [FetchFriendRequestDTO] = []
    @Published var isSearching: Bool = false
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    
    @Published var recentlySpawnedWith: [RecentlySpawnedUserDTO] = []
    @Published var searchResults: [BaseUserDTO] = []

	@Published var friendRequestCreationMessage: String = ""
	@Published var createdFriendRequest: FetchFriendRequestDTO?

	var userId: UUID
	var apiService: IAPIService
    private var cancellables = Set<AnyCancellable>()
    private var appCache: AppCache

	init(userId: UUID, apiService: IAPIService) {
		self.userId = userId
		self.apiService = apiService
        self.appCache = AppCache.shared

		if !MockAPIService.isMocking {
			
			// Subscribe to AppCache friends updates
			appCache.$friends
				.sink { [weak self] cachedFriends in
					if !cachedFriends.isEmpty {
						self?.friends = cachedFriends
						if !(self?.isSearching ?? false) {
							self?.filteredFriends = cachedFriends
						}
					}
				}
				.store(in: &cancellables)
		}
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
                } else {
                    self?.isSearching = true
                    Task {
                        await self?.fetchFilteredResults(query: query)
                        await self?.performSearch(searchText: query)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchFilteredResults(query: String) async {
        if query.isEmpty {
            await fetchAllData()
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        // Use the backend's filtered endpoint
        if let url = URL(string: APIService.baseURL + "users/filtered/\(userId)?searchQuery=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            do {
                let searchedUserResult: SearchedUserResult = try await self.apiService.fetchData(from: url, parameters: nil)
                
                await MainActor.run {
                    self.filteredIncomingFriendRequests = searchedUserResult.incomingFriendRequests
                    self.filteredRecommendedFriends = searchedUserResult.recommendedFriends
                    self.filteredFriends = searchedUserResult.friends
                    self.isLoading = false
                }
            } catch {
                print("Error fetching filtered results: \(error.localizedDescription)")
                // Fallback to local filtering if the API call fails
                await localFilterResults(query: query)
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } else {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // Local fallback filtering in case the API call fails
    private func localFilterResults(query: String) async {
        let lowercaseQuery = query.lowercased()
        
        await MainActor.run {
            self.filteredFriends = self.friends.filter { friend in
                let name = friend.name?.lowercased() ?? ""
                let username = friend.username.lowercased()
                
                return name.contains(lowercaseQuery) || 
                       username.contains(lowercaseQuery)
            }
            
            self.filteredRecommendedFriends = self.recommendedFriends.filter { friend in
                let name = friend.name?.lowercased() ?? ""
                let username = friend.username.lowercased()
                
                return name.contains(lowercaseQuery) || 
                       username.contains(lowercaseQuery)
            }
            
            self.filteredIncomingFriendRequests = self.incomingFriendRequests.filter { request in
                let friend = request.senderUser
                let name = friend.name?.lowercased() ?? ""
                let username = friend.username.lowercased()
                
                return name.contains(lowercaseQuery) || 
                       username.contains(lowercaseQuery)
            }
        }
    }

    // Remove friend from recommended list after adding
    @MainActor
    func removeFromRecommended(friendId: UUID) {
        recommendedFriends.removeAll { $0.id == friendId }
        filteredRecommendedFriends.removeAll { $0.id == friendId }
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

	func fetchAllData() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Create a task group to run these in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchIncomingFriendRequests() }
            group.addTask { await self.fetchRecommendedFriends() }
            group.addTask { await self.fetchFriends() }
            group.addTask { await self.fetchRecentlySpawnedWith() }
        }
        
        // Initialize filtered lists with full lists after fetching
        await MainActor.run {
            self.filteredFriends = self.friends
            self.filteredRecommendedFriends = self.recommendedFriends
            self.filteredIncomingFriendRequests = self.incomingFriendRequests
            self.isLoading = false
        }
	}

	internal func fetchIncomingFriendRequests() async {
		// full path: /api/v1/friend-requests/incoming/{userId}
		if let url = URL(
			string: APIService.baseURL + "friend-requests/incoming/\(userId)")
		{
			do {
				let fetchedIncomingFriendRequests: [FetchFriendRequestDTO] =
					try await self.apiService.fetchData(
						from: url, parameters: nil)

				// Ensure updating on the main thread
				await MainActor.run {
					self.incomingFriendRequests = fetchedIncomingFriendRequests
				}
			} catch {
				await MainActor.run {
					self.incomingFriendRequests = []
				}
			}
		}
	}

	internal func fetchRecommendedFriends() async {
		if let url = URL(
			string: APIService.baseURL + "users/recommended-friends/\(userId)")
		{
			do {
				let fetchedRecommendedFriends: [RecommendedFriendUserDTO] =
					try await self.apiService.fetchData(
						from: url, parameters: nil)

				// Ensure updating on the main thread
				await MainActor.run {
					self.recommendedFriends = fetchedRecommendedFriends
				}
			} catch {
				await MainActor.run {
					self.recommendedFriends = []
				}
			}
		}
	}

	func fetchFriends() async {
		// First check the cache
        if !appCache.friends.isEmpty {
            await MainActor.run {
                // Use cached data if available
                self.friends = appCache.friends
                return
            }
        }
        
        // If cache is empty or we need fresh data, fetch from API
		if let url = URL(string: APIService.baseURL + "users/friends/\(userId)")
		{
			do {
				let fetchedFriends: [FullFriendUserDTO] = try await self.apiService
					.fetchData(from: url, parameters: nil)

				// Update cache and view model
				await MainActor.run {
					self.friends = fetchedFriends
                    // Update the cache
                    self.appCache.updateFriends(fetchedFriends)
				}
			} catch {
				await MainActor.run {
					self.friends = []
				}
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
        
        var requestSucceeded = false
        
		// full path: /api/v1/friend-requests
		if let url = URL(string: APIService.baseURL + "friend-requests") {
			do {
				_ = try await self.apiService.sendData(
					createdFriendRequest, to: url, parameters: nil)
                requestSucceeded = true
			} catch {
				await MainActor.run {
					friendRequestCreationMessage =
						"There was an error creating your friend request. Please try again"
				}
			}
		}
        
        if requestSucceeded {
            // Fetch all data in parallel after successfully adding a friend
            await fetchAllData()
        } else {
            await MainActor.run {
                isLoading = false
            }
        }
	}

    func removeFriend(friendUserId: UUID) async {
        await MainActor.run {
            isLoading = true
        }
        
        var requestSucceeded = false
        
        // API endpoint for removing friend: /api/v1/users/friends/{userId}/{friendId}
        if let url = URL(string: APIService.baseURL + "users/friends/\(userId)/\(friendUserId)") {
            do {
                _ = try await self.apiService.deleteData(from: url, parameters: nil, object: Optional<String>.none)
                requestSucceeded = true
            } catch {
                print("Error removing friend: \(error.localizedDescription)")
            }
        }
        
        if requestSucceeded {
            // Remove from local arrays and refresh data
            await MainActor.run {
                self.friends.removeAll { $0.id == friendUserId }
                self.filteredFriends.removeAll { $0.id == friendUserId }
                // Update cache
                self.appCache.updateFriends(self.friends)
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }

    @MainActor
    func fetchRecentlySpawnedWith() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // API endpoint for getting recently spawned with users
            guard let url = URL(string: APIService.baseURL + "users/\(userId)/recent-users") else {
                return
            }
            
            let fetchedUsers: [RecentlySpawnedUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
            
            await MainActor.run {
                self.recentlySpawnedWith = fetchedUsers
            }
        } catch {
            print("Error fetching recently spawned users: \(error.localizedDescription)")
            // If API fails, use empty array
            self.recentlySpawnedWith = []
        }
    }
    
    @MainActor
    private func performSearch(searchText: String) async {
        if searchText.isEmpty {
            searchResults = []
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        if MockAPIService.isMocking {
            // Filter mock data for testing
            let lowercasedSearchText = searchText.lowercased()
            searchResults = BaseUserDTO.mockUsers.filter { user in
                let name = FormatterService.shared.formatName(user: user).lowercased()
                let username = user.username.lowercased()
                
                return name.contains(lowercasedSearchText) || username.contains(lowercasedSearchText)
            }
            return
        }
        
        do {
            // API endpoint for searching users: /api/v1/users/search?query={searchText}
            guard let url = URL(string: APIService.baseURL + "users/search") else {
                return
            }
            
            let fetchedUsers: [BaseUserDTO] = try await apiService.fetchData(
                from: url, 
                parameters: ["query": searchText]
            )
            self.searchResults = fetchedUsers
        } catch {
            // Handle error
        }
    }
}
