//
//  ActivityPartialUpdateDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 2025-01-28.
//

import Foundation

/// DTO for partial activity updates using PATCH requests
struct ActivityPartialUpdateDTO: Codable, Sendable {
	var title: String?
	var icon: String?
	var startTime: String?  // ISO8601 formatted string
	var endTime: String?  // ISO8601 formatted string
	var participantLimit: Int?
	var note: String?

	init(
		title: String? = nil,
		icon: String? = nil,
		startTime: String? = nil,
		endTime: String? = nil,
		participantLimit: Int? = nil,
		note: String? = nil
	) {
		self.title = title
		self.icon = icon
		self.startTime = startTime
		self.endTime = endTime
		self.participantLimit = participantLimit
		self.note = note
	}
}
