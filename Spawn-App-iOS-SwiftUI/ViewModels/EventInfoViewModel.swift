//
//  EventInfoViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import Foundation

class EventInfoViewModel: ObservableObject {
    @Published var eventInfoDisplayString: String
	@Published var imageSystemName: String

    init(event: Event, eventInfoType: EventInfoType) {
		switch eventInfoType {
			case .location:
				imageSystemName = "map"
				if let eventLocation = event.location?.locationName {
					self.eventInfoDisplayString = eventLocation
				} else {
					// nil event location (should be error?)
					self.eventInfoDisplayString = "No Location"
				}
			case .time:
				imageSystemName = "clock"
				self.eventInfoDisplayString = Self.formatEventTime(event: event)
		}
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
