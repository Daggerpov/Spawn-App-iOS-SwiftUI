//
//  FriendsListViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import Foundation

class FriendsListViewModel: ObservableObject {
    @Published var friends: [AppUser] = []
    var appUser: AppUser
    
    init(appUser: AppUser) {
        self.appUser = appUser
        self.friends = fetchFriends()
    }
    
    func fetchFriends() -> [AppUser] {
        // TODO: implement later
        return AppUser.mockAppUsers
    }
}
