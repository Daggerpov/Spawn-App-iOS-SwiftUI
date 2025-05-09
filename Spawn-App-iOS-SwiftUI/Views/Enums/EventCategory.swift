import SwiftUI

enum EventCategory: String, CaseIterable {
    case general = "General"
    case foodAndDrink = "Food & Drink"
    case active = "Active"
    case study = "Study"
    case grind = "Grind"
    
    var color: Color {
        switch self {
        case .general:
            return Color.red
        case .foodAndDrink:
            return Color.orange
        case .active:
            return Color.green
        case .study:
            return Color.blue
        case .grind:
            return Color.purple
        }
    }
} 