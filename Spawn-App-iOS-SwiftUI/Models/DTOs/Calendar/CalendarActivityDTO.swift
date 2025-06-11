import Foundation
import SwiftUI

struct CalendarActivityDTO: Codable, Identifiable {
    let id: UUID
    let date: Date
    let activityCategory: ActivityCategory?
    let icon: String?
    let colorHexCode: String?
    var activityId: UUID?
} 
