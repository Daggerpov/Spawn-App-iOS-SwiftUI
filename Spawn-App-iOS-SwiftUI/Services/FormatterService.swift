//
//  FormatterService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import Foundation
import CoreLocation

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
		return user.username ?? "User"
	}

	// Format name from a user object
	func formatName(user: Nameable) -> String {
		return user.name ?? "No Name"
	}


	
	func formatActivityTime(activity: FullFeedActivityDTO) -> String {
		let now = Date()
		let calendar = Calendar.current
		
		// Helper function to get day context for a date
		func getDayContext(for date: Date) -> String {
			if calendar.isDateInToday(date) {
				return "today"
			} else if calendar.isDateInTomorrow(date) {
				return "tomorrow"
			} else if calendar.isDateInYesterday(date) {
				return "yesterday"
			} else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
				// Same week - show day name
				let dayFormatter = DateFormatter()
				dayFormatter.dateFormat = "EEEE"
				return dayFormatter.string(from: date).lowercased()
			} else {
				// Different week/month - show full date
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "MMM d"
				return dateFormatter.string(from: date)
			}
		}
		
		// Helper function to format time with day context
		func formatTimeWithContext(for date: Date, timePrefix: String) -> String {
			let timeFormatter = DateFormatter()
			timeFormatter.dateFormat = "h:mm a"
			timeFormatter.timeZone = .current
			let timeString = timeFormatter.string(from: date)
			
			let dayContext = getDayContext(for: date)
			
			// Remove trailing "at" from prefix if it exists for special day contexts
			let basePrefix = timePrefix.hasSuffix(" at") ? String(timePrefix.dropLast(3)) : timePrefix
			
			if dayContext == "today" {
				return "\(timePrefix) \(timeString)"
			} else if dayContext == "tomorrow" {
				return "\(basePrefix) tomorrow at \(timeString)"
			} else if dayContext == "yesterday" {
				return "\(basePrefix) yesterday at \(timeString)"
			} else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
				return "\(basePrefix) \(dayContext) at \(timeString)"
			} else {
				return "\(timePrefix) \(timeString) • \(dayContext)"
			}
		}

		if let startTime = activity.startTime {
			// Check if activity has started
			let hasStarted = now >= startTime
			
			if let endTime = activity.endTime {
				let hasEnded = now >= endTime
				let isSameDay = calendar.isDate(startTime, inSameDayAs: endTime)
				
				if hasEnded {
					// Activity has completely ended
					return formatTimeWithContext(for: endTime, timePrefix: "Ended at")
				} else if hasStarted {
					// Activity is currently happening
					if isSameDay {
						let timeFormatter = DateFormatter()
						timeFormatter.dateFormat = "h:mm a"
						timeFormatter.timeZone = .current
						let startTimeString = timeFormatter.string(from: startTime)
						let endTimeString = formatTimeWithContext(for: endTime, timePrefix: "Ends at")
						return "Started at \(startTimeString) • \(endTimeString)"
					} else {
						return formatTimeWithContext(for: startTime, timePrefix: "Started at")
					}
				} else {
					// Activity hasn't started yet
					if isSameDay {
						let timeFormatter = DateFormatter()
						timeFormatter.dateFormat = "h:mm a"
						timeFormatter.timeZone = .current
						let startTimeString = timeFormatter.string(from: startTime)
						let endTimeString = timeFormatter.string(from: endTime)
						
						let dayContext = getDayContext(for: startTime)
						if dayContext == "today" {
							return "\(startTimeString) - \(endTimeString)"
						} else if dayContext == "tomorrow" {
							return "Tomorrow \(startTimeString) - \(endTimeString)"
						} else if dayContext == "yesterday" {
							return "Yesterday \(startTimeString) - \(endTimeString)"
						} else if calendar.isDate(startTime, equalTo: now, toGranularity: .weekOfYear) {
							return "\(dayContext.capitalized) \(startTimeString) - \(endTimeString)"
						} else {
							return "\(startTimeString) - \(endTimeString) • \(dayContext)"
						}
					} else {
						return formatTimeWithContext(for: startTime, timePrefix: "Starts at")
					}
				}
			} else {
				// No end time specified
				if hasStarted {
					return formatTimeWithContext(for: startTime, timePrefix: "Started at")
				} else {
					return formatTimeWithContext(for: startTime, timePrefix: "Starts at")
				}
			}
		} else if let endTime = activity.endTime {
			// Only end time specified
			let hasEnded = now >= endTime
			if hasEnded {
				return formatTimeWithContext(for: endTime, timePrefix: "Ended at")
			} else {
				return formatTimeWithContext(for: endTime, timePrefix: "Ends at")
			}
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
    
    func atTime(at date: Date) -> String {
        let daysAgo = Int(floor(date.timeIntervalSinceNow))
        
        if daysAgo < 1 {
            return date.formatted(date: .omitted, time: .shortened)
        } else {
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "d/M"
            return dateFormat.string(from: date)
        }
    }
 
    // Short chat timestamp used next to sender names
    // - Under 24h: relative compact (e.g., 45m ago, 2h ago, 30s ago)
    // - 24h or older: clock time (e.g., 12:30pm)
    func chatTimestamp(from date: Date) -> String {
        let now = Date()
        let seconds = Int(now.timeIntervalSince(date))
        let minute = 60
        let hour = 3600
        let day = 86400
        if seconds < minute {
            return seconds <= 1 ? "1s ago" : "\(seconds)s ago"
        } else if seconds < hour {
            let minutes = seconds / minute
            return minutes == 1 ? "1m ago" : "\(minutes)m ago"
        } else if seconds < day {
            let hours = seconds / hour
            return hours == 1 ? "1h ago" : "\(hours)h ago"
        } else {
            // Show clock time for older messages
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mma" // e.g., 12:30PM
            formatter.amSymbol = "am"
            formatter.pmSymbol = "pm"
            var timeString = formatter.string(from: date).lowercased()
            // Remove any extraneous spaces before am/pm (just in case)
            timeString = timeString.replacingOccurrences(of: " ", with: "")
            return timeString
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
        if interval <= 0 { return "Happening Now" }
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "In \(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "In \(minutes) min\(minutes > 1 ? "s" : "")"
        }
    }
    
    func distanceString(from userLocation: CLLocationCoordinate2D?, to activityLocation: LocationDTO?) -> String {
        guard let userLocation = userLocation,
              let activityLocation = activityLocation else {
            return "Distance unavailable"
        }
        
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let activityCLLocation = CLLocation(latitude: activityLocation.latitude, longitude: activityLocation.longitude)
        
        let distance = userCLLocation.distance(from: activityCLLocation) // Distance in meters
        
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let km = distance / 1000
            if km < 10 {
                return String(format: "%.1fkm", km)
            } else {
                return "\(Int(km))km"
            }
        }
    }
    
}
