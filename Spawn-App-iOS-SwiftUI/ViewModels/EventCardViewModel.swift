//
//  EventCardViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class EventCardViewModel: ObservableObject {
    @Published var eventTimeDisplayString: String = ""
    
    var event: Event
    
    init(event: Event) {
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
}
