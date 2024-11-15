//
//  FriendsListViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import Foundation

class FriendsListViewModel: ObservableObject {
    @Published var friends: [AppUser] = []
    @Published var searchText: String = ""
    var appUser: AppUser
    
    init(appUser: AppUser) {
        self.appUser = appUser
        self.friends = fetchFriends()
    }
    
    func fetchFriends() -> [AppUser] {
        guard let baseUserFriends = appUser.baseUser.friends else { return [] }
        
        return baseUserFriends.compactMap { friend in
            AppUserService.shared.appUserLookup[friend.id] ?? AppUser.emptyUser
        }
    }
    
    func fetchFriendTags() -> [FriendTag] {
        return appUser.friendTags ?? []
    }
}
