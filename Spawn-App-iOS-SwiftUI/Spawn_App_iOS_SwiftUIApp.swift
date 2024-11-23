//
//  Spawn_App_iOS_SwiftUIApp.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/3/24.
//

import SwiftUI

@main
struct Spawn_App_iOS_SwiftUIApp: App {
    @StateObject var observableUser = ObservableUser(user: .danielAgapov) // Shared instance
    
    var body: some Scene {
        WindowGroup {
            FeedView()
                .environmentObject(observableUser) // Inject the observable user into the environment
        }
    }
}

class ObservableUser: ObservableObject {
    @Published private(set) var user: User
    
    init(user: User) {
        self.user = user
    }
    
    var id: UUID {
        user.id
    }
    
    var friends: [User]? {
        user.friends
    }
    var username: String {
        user.username
    }
    var profilePicture: String? {
        user.profilePicture
    }
    
    var firstName: String? {
        user.firstName
    }
    var lastName: String? {
        user.lastName
    }
    var bio: String? {
        user.bio
    }
    var friendTags: [FriendTag]? {
        user.friendTags
    }
}
