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
		// TODO DANIEL: switch to API call
        self.isParticipating = ((event.participantUsers?.contains(where: { user in
            user.id == user.id
        })) != nil)

    }
    
    public func toggleParticipation() -> Void {
		// TODO DANIEL: switch to API call
        if isParticipating {
            // remove user
            event.participantUsers?.removeAll(where: { user in
                user.id == user.id
            })
            isParticipating = false
        } else {
            event.participantUsers?.append(user)
            isParticipating = true
        }
    }
}
