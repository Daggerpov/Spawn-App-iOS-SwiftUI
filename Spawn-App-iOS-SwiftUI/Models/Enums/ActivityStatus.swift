//
//  ActivityStatus.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/13/25.
//
import SwiftUI

public enum ActivityStatus {
    case laterToday
    case inHours(Int)
    case happeningNow
    case inDays(Int)
    case past
    case inMinutes(Int)
    
    var displayText: String {
        switch self {
        case .happeningNow:
            return "Happening Now"
        case .inHours(let hours):
            return "In \(hours) hour\(hours == 1 ? "" : "s")"
        case .laterToday:
            return "Later Today"
        case .inDays(let days):
            return days == 1 ? "Tomorrow" : "In \(days) days"
        case .past:
            return "Already Happened"
        case .inMinutes(let minutes):
            return "In \(minutes) min\(minutes == 1 ? "" : "s")"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .happeningNow:
            return Color(red: 70/255, green: 222/255, blue: 161/255)
        default:
            return Color.white.opacity(0.8)
        }
    }
}
