//
//  AppUserService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

final class AppUserService {
    static let shared = AppUserService(appUsers: AppUser.mockAppUsers)
    
    var appUsers: [AppUser]
    
    private init(appUsers: [AppUser]) {
        self.appUsers = appUsers
    }
    
    public var appUserLookup: [UUID: AppUser] {
        var lookupDict: [UUID: AppUser] = [:]
        for user in appUsers {
            lookupDict[user.id] = user // This will replace any duplicate with the last occurrence
        }
        return lookupDict
    }
}
