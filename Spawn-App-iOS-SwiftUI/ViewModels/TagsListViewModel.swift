//
//  TagsListViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import Foundation

class TagsListViewModel: ObservableObject {
    @Published var friendTags: [FriendTag] = []
    @Published var searchText: String = ""
    var appUser: AppUser
    
    init(appUser: AppUser) {
        self.appUser = appUser
        self.friendTags = fetchTags()
    }
    
    func fetchTags() -> [FriendTag] {
        // TODO: implement later
//        guard let baseUserFriends = appUser.baseUser.friends else { return [] }
//        
//        return baseUserFriends.compactMap { friend in
//            AppUserService.shared.appUserLookup[friend.id] ?? AppUser.emptyUser
//        }
        // change to event tags
        
        return FriendTag.mockTags
    }
}
