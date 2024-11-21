//
//  EventDescriptionViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

class EventDescriptionViewModel: ObservableObject {
    @Published var Users: [User]
    var event: Event
    
    init(event: Event, Users: [User] = []) {
        self.event = event
        self.Users = Users
    }
}
