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
    var user: User
    
    init(user: User) {
        self.User = User
        self.friendTags = fetchTags()
    }
    
    func fetchTags() -> [FriendTag] {
        // TODO: implement later
//        guard let baseUserFriends = user.baseuser.friends else { return [] }
//        
//        return baseUserFriends.compactMap { friend in
//            UserService.shared.UserLookup[friend.id] ?? user.emptyUser
//        }
        // change to event tags
        
        return FriendTag.mockTags
    }
}
