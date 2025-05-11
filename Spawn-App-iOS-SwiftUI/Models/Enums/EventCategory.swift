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

    // Custom initializer for decoding, handling null values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // First, check if the value is null
        if container.decodeNil() {
            // Default to general if null
            self = .general
            return
        }
        
        // Otherwise try to decode the string value
        let rawValue = try container.decode(String.self)
        if let value = EventCategory(rawValue: rawValue) {
            self = value
        } else {
            // If string doesn't match any case, default to general
            self = .general
        }
    }

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

    func color() -> Color {
        switch self {
        case .foodAndDrink: return .green
        case .active: return .blue
        case .grind: return .purple
        case .chill: return .orange
        case .general: return .gray
        }
    }

    func systemIcon() -> String {
        switch self {
        case .foodAndDrink: return "fork.knife"
        case .active: return "figure.walk"
        case .grind: return "briefcase.fill"
        case .chill: return "sofa.fill"
        case .general: return "star.fill"
        }
    }
}
