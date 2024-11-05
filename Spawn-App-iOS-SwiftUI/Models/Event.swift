//
//  Event.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel on 11/4/24.
//

import Foundation

struct Event: Identifiable, Codable {
    var id: UUID
    var title: String
    var startTime: String // TODO: change to proper time later
    var endTime: String // TODO: change to proper time later
    var location: String // TODO: change to proper location later
    var symbolName: String // TODO: maybe change later?
}

extension Event {
    static let mockEvents: [Event] = [
        Event(
            id: UUID(),
            title: "Morning Yoga",
            startTime: "08:00 AM",
            endTime: "09:00 AM",
            location: "City Park",
            symbolName: "checkmark"
        ),
        Event(
            id: UUID(),
            title: "Work Meeting",
            startTime: "10:00 AM",
            endTime: "11:00 AM",
            location: "Office",
            symbolName: "star.fill"
        ),
        Event(
            id: UUID(),
            title: "Lunch with Sarah",
            startTime: "12:30 PM",
            endTime: "01:30 PM",
            location: "Downtown Cafe",
            symbolName: "star.fill"
        ),
        Event(
            id: UUID(),
            title: "Evening Run",
            startTime: "06:00 PM",
            endTime: "07:00 PM",
            location: "Riverside Park",
            symbolName: "star.fill"
        )
    ]
}
