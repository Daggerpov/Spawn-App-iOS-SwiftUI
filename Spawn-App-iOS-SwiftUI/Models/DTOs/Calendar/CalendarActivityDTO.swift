import Foundation
import SwiftUI

struct CalendarActivityDTO: Codable, Identifiable {
    let id: UUID
    let date: Date // Changed from String to Date
    let eventCategory: EventCategory? // Using EventCategory enum, now optional
    let icon: String?
    var eventId: UUID?
} 