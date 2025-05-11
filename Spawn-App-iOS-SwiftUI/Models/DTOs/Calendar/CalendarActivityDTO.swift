import Foundation

struct CalendarActivityDTO: Codable, Identifiable {
    let id: UUID
    let title: String
    let date: Date // Changed from String to Date
    let activityType: String
    var eventId: UUID?
    var userId: UUID?
} 