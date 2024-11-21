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
        self.User = User
        self.friends = fetchFriends()
        self.recommendedFriends = fetchRecommendedFriends()
    }
    
    func fetchFriends() -> [User] {
        guard let baseUserFriends = user.baseuser.friends else { return [] }
        
        return baseUserFriends.compactMap { friend in
            UserService.shared.UserLookup[friend.id] ?? user.emptyUser
        }
    }
    
    func fetchRecommendedFriends() -> [User] {
        let allMockUsers = user.mockUsers
        
        let recommended = allMockUsers.filter { mockUser in
            // Check if the mock user is not in the friends list
            // and if the mock user isn't the own user themselves
            return mockuser.id != user.id && !self.friends.contains(where: { $0.id == mockuser.id })
        }
        
        return recommended
    }

    
    func fetchFriendTags() -> [FriendTag] {
        return user.friendTags ?? []
    }
}
