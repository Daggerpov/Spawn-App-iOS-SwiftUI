//
//  FriendListingViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import Foundation

class FriendListingViewModel: ObservableObject {
    @Published var tagsForFriend: [FriendTag] = []
    var friend: AppUser
    var appUser: AppUser
    
    init(friend: AppUser, appUser: AppUser) {
        self.friend = friend
        self.appUser = appUser
        fetchTagsForFriend()
    }
    
    private func fetchTagsForFriend() -> Void {
        guard let friendTags = appUser.friendTags else { return }
        
        tagsForFriend = friendTags.filter { friendTag in
            friendTag.friends?.contains(where: { $0.id == friend.id }) == true
        }
    }
}
