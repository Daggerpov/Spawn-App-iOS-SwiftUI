//
//  CreateChatMessageDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-03-06.
//

import Foundation

// Will correspond to `CreateChatMessageDTO` in the back-end:
// Note: No `id` field - the server generates the ID when creating the message
struct CreateChatMessageDTO: Codable, Sendable {
	var content: String
	var senderUserId: UUID
	var activityId: UUID

	init(
		content: String, senderUserId: UUID,
		activityId: UUID
	) {
		self.content = content
		self.senderUserId = senderUserId
		self.activityId = activityId
	}
}
