//
//  EventDescriptionViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

class EventDescriptionViewModel: ObservableObject {
    @Published var appUsers: [AppUser]
    var event: Event
    
    init(event: Event, appUsers: [AppUser] = []) {
        self.event = event
        self.appUsers = appUsers
    }
    
    public var appUserLookup: [UUID: AppUser] {
        // look-up app user by id from user
        Dictionary(uniqueKeysWithValues: appUsers.map { ($0.id, $0) })
    }
}
