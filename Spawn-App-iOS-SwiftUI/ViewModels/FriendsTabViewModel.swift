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

	@Published var friendRequestCreationMessage: String = ""
	@Published var createdFriendRequest: FetchFriendRequestDTO?

	var userId: UUID
	var apiService: IAPIService
    private var cancellables = Set<AnyCancellable>()

	init(userId: UUID, apiService: IAPIService) {
		self.userId = userId
		self.apiService = apiService
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
        
        // Use the backend's filtered endpoint
        if let url = URL(string: APIService.baseURL + "users/filtered/\(userId)?searchQuery=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            do {
                let searchedUserResult: SearchedUserResult = try await self.apiService.fetchData(from: url, parameters: nil)
                
                await MainActor.run {
                    self.filteredIncomingFriendRequests = searchedUserResult.incomingFriendRequests
                    self.filteredRecommendedFriends = searchedUserResult.recommendedFriends
                    self.filteredFriends = searchedUserResult.friends
                }
            } catch {
                print("Error fetching filtered results: \(error.localizedDescription)")
                // Fallback to local filtering if the API call fails
                await localFilterResults(query: query)
            }
        }
    }
    
    // Local fallback filtering in case the API call fails
    private func localFilterResults(query: String) async {
        let lowercaseQuery = query.lowercased()
        
        await MainActor.run {
            self.filteredFriends = self.friends.filter { friend in
                let firstName = friend.firstName?.lowercased() ?? ""
                let lastName = friend.lastName?.lowercased() ?? ""
                let username = friend.username.lowercased()
                
                return firstName.contains(lowercaseQuery) || 
                       lastName.contains(lowercaseQuery) || 
                       username.contains(lowercaseQuery)
            }
            
            self.filteredRecommendedFriends = self.recommendedFriends.filter { friend in
                let firstName = friend.firstName?.lowercased() ?? ""
                let lastName = friend.lastName?.lowercased() ?? ""
                let username = friend.username.lowercased()
                
                return firstName.contains(lowercaseQuery) || 
                       lastName.contains(lowercaseQuery) || 
                       username.contains(lowercaseQuery)
            }
            
            self.filteredIncomingFriendRequests = self.incomingFriendRequests.filter { request in
                let friend = request.senderUser
                let firstName = friend.firstName?.lowercased() ?? ""
                let lastName = friend.lastName?.lowercased() ?? ""
                let username = friend.username.lowercased()
                
                return firstName.contains(lowercaseQuery) || 
                       lastName.contains(lowercaseQuery) || 
                       username.contains(lowercaseQuery)
            }
        }
    }

	func fetchAllData() async {
        // Create a task group to run these in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchIncomingFriendRequests() }
            group.addTask { await self.fetchRecommendedFriends() }
            group.addTask { await self.fetchFriends() }
        }
        
        // Initialize filtered lists with full lists after fetching
        await MainActor.run {
            self.filteredFriends = self.friends
            self.filteredRecommendedFriends = self.recommendedFriends
            self.filteredIncomingFriendRequests = self.incomingFriendRequests
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

	internal func fetchFriends() async {
		if let url = URL(string: APIService.baseURL + "users/friends/\(userId)")
		{
			do {
				let fetchedFriends: [FullFriendUserDTO] = try await self.apiService
					.fetchData(from: url, parameters: nil)

				// Ensure updating on the main thread
				await MainActor.run {
					self.friends = fetchedFriends
				}
			} catch {
				await MainActor.run {
					self.friends = []
				}
			}
		}
	}

	func addFriend(friendUserId: UUID) async {
		let createdFriendRequest = CreateFriendRequestDTO(
			id: UUID(),
			senderUserId: userId,
			receiverUserId: friendUserId
		)
		// full path: /api/v1/friend-requests
		if let url = URL(string: APIService.baseURL + "friend-requests") {
			do {
				_ = try await self.apiService.sendData(
					createdFriendRequest, to: url, parameters: nil)
			} catch {
				await MainActor.run {
					friendRequestCreationMessage =
						"There was an error creating your friend request. Please try again"
				}
			}
		}
		await fetchAllData()
	}
}
