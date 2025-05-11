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
    case grind = "GRIND"
    case chill = "CHILL"

    var displayName: String {
        switch self {
        case .general:
            return "General"
        case .foodAndDrink:
            return "Food & Drink"
        case .active:
            return "Active"
        case .grind:
            return "Grind"
        case .chill:
            return "Chill"
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
            case .grind:
                return .gray
            case .chill:
                return .purple
        }
    }
}
