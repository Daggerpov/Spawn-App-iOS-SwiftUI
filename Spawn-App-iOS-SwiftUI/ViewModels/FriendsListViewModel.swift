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
    var user: User
    
    init(user: User) {
        self.user = user
        self.friends = fetchFriends()
        self.recommendedFriends = fetchRecommendedFriends()
    }
    
    func fetchFriends() -> [User] {
        guard let baseUserFriends = user.friends else { return [] }
        
        return baseUserFriends
    }
    
    func fetchRecommendedFriends() -> [User] {
        let allMockUsers = User.mockUsers
        
        let recommended = allMockUsers.filter { mockUser in
            // Check if the mock user is not in the friends list
            // and if the mock user isn't the own user themselves
            return mockUser.id != user.id && !self.friends.contains(where: { $0.id == mockUser.id })
        }
        
        return recommended
    }

    
    func fetchFriendTags() -> [FriendTag] {
        return user.friendTags ?? []
    }
}
