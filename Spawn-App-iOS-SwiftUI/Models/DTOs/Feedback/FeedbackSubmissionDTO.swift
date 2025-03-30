//
//  FetchFeedbackSubmissionDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Claude on 2025-02-18.
//

import Foundation

struct FetchFeedbackSubmissionDTO: Codable, Identifiable {
    var id: UUID?
    var type: FeedbackType
    var fromUserId: UUID?
    var fromUserEmail: String?
    var message: String
    var isResolved: Bool?
    var resolutionComment: String?
    var submittedAt: Date?
    
    init(type: FeedbackType, fromUserId: UUID? = nil, message: String) {
        self.type = type
        self.fromUserId = fromUserId
        self.message = message
    }
} 