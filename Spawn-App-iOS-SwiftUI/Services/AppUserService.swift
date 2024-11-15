//
//  AppUserService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

final class AppUserService {
    static let shared: AppUserService = AppUserService(
        appUsers: AppUser.mockAppUsers,
        users: User.mockUsers
    )
    
    var appUsers: [AppUser]
    var users: [User]
    
    private init(appUsers: [AppUser], users: [User]) {
        self.appUsers = appUsers
        self.users = users
    }
    
    public var appUserLookup: [UUID: AppUser] {
        var lookupDict: [UUID: AppUser] = [:]
        for currentAppUser in appUsers {
            lookupDict[currentAppUser.id] = currentAppUser // This will replace any duplicate with the last occurrence
        }
        return lookupDict
    }
    
    public var userLookup: [UUID: User] {
        var lookupDict: [UUID: User] = [:]
        for currentUser in users {
            lookupDict[currentUser.id] = currentUser
        }
        return lookupDict
    }
}
