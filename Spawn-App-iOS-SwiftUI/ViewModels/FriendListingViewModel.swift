//
//  FriendListingViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import Foundation

class FriendListingViewModel: ObservableObject {
    @Published var tagsForFriend: [FriendTag] = []
    var person: User
    var user: User
    var isFriend: Bool
    var formattedFriendName: String = ""
    
    init(person: User, user: User, isFriend: Bool) {
        self.person = person
        self.user = user
        self.isFriend = isFriend
        self.formattedFriendName = fetchFormattedFriendName()
        fetchTagsForFriend()
    }
    
    private func fetchTagsForFriend() -> Void {
        if isFriend {
            guard let friendTags = user.friendTags else { return }
            
            tagsForFriend = friendTags.filter { friendTag in
                friendTag.friends?.contains(where: { $0.id == person.id }) == true
            }
        }
    }
    
    private func fetchFormattedFriendName() -> String {
        return FormatterService.shared.formatName(user: person)
    }
    
    public func addFriend() -> Void {
        // TODO: fill in later
        
        self.isFriend = true
    }
}
