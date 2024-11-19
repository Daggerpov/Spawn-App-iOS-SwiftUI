//
//  FriendsListViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import Foundation

class FriendsListViewModel: ObservableObject {
    @Published var friends: [AppUser] = []
    @Published var recommendedFriends: [AppUser] = []
    var appUser: AppUser
    
    init(appUser: AppUser) {
        self.appUser = appUser
        self.friends = fetchFriends()
        self.recommendedFriends = fetchRecommendedFriends()
    }
    
    func fetchFriends() -> [AppUser] {
        guard let baseUserFriends = appUser.baseUser.friends else { return [] }
        
        return baseUserFriends.compactMap { friend in
            AppUserService.shared.appUserLookup[friend.id] ?? AppUser.emptyUser
        }
    }
    
    func fetchRecommendedFriends() -> [AppUser] {
        let allMockUsers = AppUser.mockAppUsers
        
        let recommended = allMockUsers.filter { mockUser in
            // Check if the mock user is not in the friends list
            // and if the mock user isn't the own user themselves
            return mockUser.id != appUser.id && !self.friends.contains(where: { $0.id == mockUser.id })
        }
        
        return recommended
    }

    
    func fetchFriendTags() -> [FriendTag] {
        return appUser.friendTags ?? []
    }
}
