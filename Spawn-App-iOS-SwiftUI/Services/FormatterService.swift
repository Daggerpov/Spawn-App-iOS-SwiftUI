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

	// `Nameable` applies to either `UserDTO` or `PotentialFriendUserDTO`, making
	// either of those a valid param to this method.
	public func formatName(user: Nameable) -> String {
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
				Calendar.current.isDate(startTime, inSameDayAs: endTime)
			{
				return
					"\(dateFormatter.string(from: startTime)) - \(dateFormatter.string(from: endTime))"
			}
			return "Starts at \(dateFormatter.string(from: startTime))"
		} else if let endTime = event.endTime {
			return "Ends at \(dateFormatter.string(from: endTime))"
		} else {
			return "No Time Available"
		}
	}

	func timeAgo(from date: Date) -> String {
		let now = Date()
		let secondsAgo = Int(now.timeIntervalSince(date))

		let minute = 60
		let hour = 3600
		let day = 86400

		if secondsAgo < minute {
			return secondsAgo == 1
				? "1 second ago" : "\(secondsAgo) seconds ago"
		} else if secondsAgo < hour {
			let minutes = secondsAgo / minute
			return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
		} else if secondsAgo < day {
			let hours = secondsAgo / hour
			return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
		} else {
			let days = secondsAgo / day
			return days == 1 ? "1 day ago" : "\(days) days ago"
		}
	}
}
