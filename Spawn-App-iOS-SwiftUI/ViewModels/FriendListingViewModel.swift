//
//  FriendListingViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import Foundation

class FriendListingViewModel: ObservableObject {
    @Published var tagsForFriend: [FriendTag] = []
    var person: AppUser
    var appUser: AppUser
    var isFriend: Bool
    var formattedFriendName: String = ""
    
    init(person: AppUser, appUser: AppUser, isFriend: Bool) {
        self.person = person
        self.appUser = appUser
        self.isFriend = isFriend
        self.formattedFriendName = fetchFormattedFriendName()
        fetchTagsForFriend()
    }
    
    private func fetchTagsForFriend() -> Void {
        if isFriend {
            guard let friendTags = appUser.friendTags else { return }
            
            tagsForFriend = friendTags.filter { friendTag in
                friendTag.friends?.contains(where: { $0.id == person.id }) == true
            }
        }
    }
    
    private func fetchFormattedFriendName() -> String {
        return NameFormatterService.shared.formatName(appUser: person)
    }
    
    public func addFriend() -> Void {
        // TODO: fill in later
        
        self.isFriend = true
    }
}
