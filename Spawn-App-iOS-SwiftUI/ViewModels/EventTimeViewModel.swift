//
//  EventTimeViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import Foundation

class EventTimeViewModel: ObservableObject {
    @Published var eventTimeDisplayString: String = ""
    
    init(event: Event) {
        self.eventTimeDisplayString = Self.formatEventTime(event: event)
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
