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
}
