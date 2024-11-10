//
//  EventCardViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class EventCardViewModel: ObservableObject {
    @Published var eventTimeDisplayString: String = ""
    @Published var isParticipating: Bool = false
    
    var appUser: AppUser
    var event: Event

    init(appUser: AppUser, event: Event) {
        self.appUser = appUser
        self.event = event
        self.eventTimeDisplayString = EventCardViewModel.formatEventTime(event: event)
    }
    
    static func formatEventTime(event: Event) -> String {
        var eventTimeDisplayStringLocal: String = ""
        if let eventStartTime = event.startTime {
            if let eventEndTime = event.endTime {
                eventTimeDisplayStringLocal += "\(eventStartTime) — \(eventEndTime)"
            } else {
                eventTimeDisplayStringLocal = "Starts at \(eventStartTime)"
            }
        } else {
            // no start time
            if let eventEndTime = event.endTime {
                eventTimeDisplayStringLocal = "Ends at \(eventEndTime)"
            }
        }
        return eventTimeDisplayStringLocal
    }
    
    /// returns whether the logged in app user is part of the event's participants array
    public func fetchIsParticipating() -> Void {
        self.isParticipating = ((event.participants?.contains(where: { user in
            user.id == appUser.id
        })) != nil)
    }
}
