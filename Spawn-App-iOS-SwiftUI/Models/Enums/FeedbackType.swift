//
//  FeedbackType.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Claude on 2025-02-18.
//

import Foundation

enum FeedbackType: String, Codable, CaseIterable, Identifiable {
    case BUG_REPORT
    case FEATURE_REQUEST 
    case GENERAL_FEEDBACK
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .BUG_REPORT:
            return "Bug Report"
        case .FEATURE_REQUEST:
            return "Feature Request"
        case .GENERAL_FEEDBACK:
            return "General Feedback"
        }
    }
    
    var iconName: String {
        switch self {
        case .BUG_REPORT:
            return "ant"
        case .FEATURE_REQUEST:
            return "lightbulb"
        case .GENERAL_FEEDBACK:
            return "message"
        }
    }
} 