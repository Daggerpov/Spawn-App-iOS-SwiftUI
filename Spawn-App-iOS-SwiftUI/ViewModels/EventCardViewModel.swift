//
//  EventCardViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class EventCardViewModel: ObservableObject {
    @Published var isParticipating: Bool = false
	var apiService: IAPIService
    var user: User
    var event: Event

	init(apiService: IAPIService, user: User, event: Event) {
		self.apiService = apiService
        self.user = user
        self.event = event
    }
    
    /// returns whether the logged in app user is part of the event's participants array
    public func fetchIsParticipating() -> Void {
        self.isParticipating = ((event.participants?.contains(where: { user in
            user.id == user.id
        })) != nil)

    }
    
    public func toggleParticipation() -> Void {
        if isParticipating {
            // remove user
            event.participants?.removeAll(where: { user in
                user.id == user.id
            })
            isParticipating = false
        } else {
            event.participants?.append(user)
            isParticipating = true
        }
    }
}
