//
//  EventCardViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class EventCardViewModel: ObservableObject {
    @Published var isParticipating: Bool = false
    var appUser: AppUser
    var event: Event

    init(appUser: AppUser, event: Event) {
        self.appUser = appUser
        self.event = event
        
    }
    
    /// returns whether the logged in app user is part of the event's participants array
    public func fetchIsParticipating() -> Void {
        self.isParticipating = ((event.participants?.contains(where: { user in
            user.id == appUser.id
        })) != nil)
    }
    
    public func toggleParticipation() -> Void {
        if isParticipating {
            // remove user
            event.participants?.removeAll(where: { user in
                user.id == appUser.id
            })
            isParticipating = false
        } else {
            // join participants
            if let user = AppUserService.shared.userLookup[appUser.id]{
                event.participants?.append(user)
            }
            isParticipating = true
        }
    }
}
