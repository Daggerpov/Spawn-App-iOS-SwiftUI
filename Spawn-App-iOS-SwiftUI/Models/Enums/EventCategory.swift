//
//  EventCategory.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-27.
//

import Foundation
import SwiftUI

enum EventCategory: String, Codable, CaseIterable {
    case general = "GENERAL"
    case foodAndDrink = "FOOD_AND_DRINK"
    case active = "ACTIVE"
    case study = "STUDY"
    case grind = "GRIND"

    var rawValue: String {
        switch self {
        case .general:
            return "General"
        case .foodAndDrink:
            return "Food & Drink"
        case .active:
            return "Active"
        case .study:
            return "Study"
        case .grind:
            return "Grind"
        }
    }

    var color: Color {
        switch self {
        case .general:
            return .red
        case .foodAndDrink:
            return .pink
        case .active:
            return .blue
        case .study:
            return .gray
        case .grind:
            return Color.purple
        }
    }
}
