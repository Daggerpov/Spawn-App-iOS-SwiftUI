//
//  FormatterService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

class FormatterService {
    static let shared: FormatterService = FormatterService()
    
    private init() {}
    
    public func formatName(user: User) -> String {
        if let firstName = user.firstName {
            if let lastName = user.lastName {
                return "\(firstName) \(lastName)"
            } else {
                return firstName
            }
        }
        if let lastName = user.lastName {
            return lastName
        }
        return ""
    }

	public func formatEventTime(event: Event) -> String {
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
