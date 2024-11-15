//
//  TagsListViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import Foundation

class TagsListViewModel: ObservableObject {
    @Published var friendTags: [FriendTag] = []
    var appUser: AppUser
    
    init(appUser: AppUser) {
        self.appUser = appUser
        self.friendTags = fetchTags()
    }
    
    func fetchTags() -> [FriendTag] {
        // TODO: implement later
        return FriendTag.mockTags
    }
}
