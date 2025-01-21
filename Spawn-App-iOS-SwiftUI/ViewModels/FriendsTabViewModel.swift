//
//  FriendsTabViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

class FriendsTabViewModel: ObservableObject {
	@Published var incomingFriendRequests: [FriendRequest]
	@Published var recommendedFriends: [User]
	@Published var friends: [User]

	var apiService: IAPIService

	init(apiService, IAPIService) {
		self.apiService = apiService
	}

	func fetchAllData() {
		fetchIncomingFriendRequests()
		fetchRecommendedFriends()
		fetchFriends()
	}

	internal func fetchIncomingFriendRequests () {
		
	}
}
