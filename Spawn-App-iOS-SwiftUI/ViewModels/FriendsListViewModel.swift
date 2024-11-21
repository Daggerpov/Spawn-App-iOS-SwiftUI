//
//  FriendsListViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import Foundation

class FriendsListViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var recommendedFriends: [User] = []
    var User: User
    
    init(User: User) {
        self.User = User
        self.friends = fetchFriends()
        self.recommendedFriends = fetchRecommendedFriends()
    }
    
    func fetchFriends() -> [User] {
        guard let baseUserFriends = User.baseUser.friends else { return [] }
        
        return baseUserFriends.compactMap { friend in
            UserService.shared.UserLookup[friend.id] ?? User.emptyUser
        }
    }
    
    func fetchRecommendedFriends() -> [User] {
        let allMockUsers = User.mockUsers
        
        let recommended = allMockUsers.filter { mockUser in
            // Check if the mock user is not in the friends list
            // and if the mock user isn't the own user themselves
            return mockUser.id != User.id && !self.friends.contains(where: { $0.id == mockUser.id })
        }
        
        return recommended
    }

    
    func fetchFriendTags() -> [FriendTag] {
        return User.friendTags ?? []
    }
}
