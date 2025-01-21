//
//  FormatterService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import Foundation

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

	func formatEventTime(event: Event) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "h:mm a"
		dateFormatter.timeZone = .current

		if let startTime = event.startTime {
			if let endTime = event.endTime,
				Calendar.current.isDate(startTime, inSameDayAs: endTime) {
				return "\(dateFormatter.string(from: startTime)) - \(dateFormatter.string(from: endTime))"
			}
			return "Starts at \(dateFormatter.string(from: startTime))"
		} else if let endTime = event.endTime {
			return "Ends at \(dateFormatter.string(from: endTime))"
		} else {
			return "No Time Available"
		}
	}
}
