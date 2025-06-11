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

	func formatFirstName(user: Nameable) -> String {
		// Split the name and get the first component as the first name
		if let fullName = user.name, !fullName.isEmpty {
			let components = fullName.components(separatedBy: " ")
			if let firstName = components.first {
				return firstName
			}
		}
		// Fallback to username if no name available
		return user.username
	}

	// Format name from a user object
	func formatName(user: Nameable) -> String {
		return user.name ?? "No Name"
	}

	func formatEventTime(event: FullFeedEventDTO) -> String {
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

	// Format Instagram link to ensure proper storage format
	func formatInstagramLink(_ link: String) -> String {
		let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.isEmpty { return "" }
		
		// If it starts with @, remove it for storage (we'll add it back when displaying)
		if trimmed.hasPrefix("@") {
			return String(trimmed.dropFirst())
		}
		
		// If it's a full URL, extract just the username
		if trimmed.lowercased().contains("instagram.com/") {
			if let username = trimmed.components(separatedBy: "instagram.com/").last {
				return username.components(separatedBy: "/").first ?? trimmed
			}
		}
		
		return trimmed
	}
	
	// Format WhatsApp link to ensure proper storage format
	func formatWhatsAppLink(_ link: String) -> String {
		let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.isEmpty { return "" }
		
		// Remove any non-numeric characters for phone number
		let numericOnly = trimmed.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
		
		// Ensure it's a valid length for a phone number (at least 10 digits)
		if numericOnly.count >= 10 {
			return numericOnly
		}
		
		// If not a valid phone number format, return original (trimmed)
		return trimmed
	}
    
    
    func timeUntil(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "Started" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "\(minutes) min\(minutes > 1 ? "s" : "")"
        }
    }
    
    func distanceString() -> String {
        // TODO: Replace with real distance calculation if available
        return "2km"
    }
}
