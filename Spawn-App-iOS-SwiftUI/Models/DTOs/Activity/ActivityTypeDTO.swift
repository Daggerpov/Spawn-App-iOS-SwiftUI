//
//  ActivityTypeDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/31/25.
//
import Foundation

struct ActivityTypeDTO: Identifiable, Codable, Equatable, Sendable {
	var id: UUID
	var title: String
	var associatedFriends: [BaseUserDTO]
	var icon: String
	var orderNum: Int
	var ownerUserId: UUID?
	var isPinned: Bool

	init(
		id: UUID, title: String, icon: String, associatedFriends: [BaseUserDTO], orderNum: Int,
		ownerUserId: UUID? = nil, isPinned: Bool = false
	) {
		self.id = id
		self.title = title
		self.associatedFriends = associatedFriends
		self.icon = icon
		self.orderNum = orderNum
		self.ownerUserId = ownerUserId
		self.isPinned = isPinned
	}
}

// DTO for batch updating activity types
struct BatchActivityTypeUpdateDTO: Codable, Sendable {
	let updatedActivityTypes: [ActivityTypeDTO]
	let deletedActivityTypeIds: [UUID]

	init(updatedActivityTypes: [ActivityTypeDTO] = [], deletedActivityTypeIds: [UUID] = []) {
		self.updatedActivityTypes = updatedActivityTypes
		self.deletedActivityTypeIds = deletedActivityTypeIds
	}
}

extension ActivityTypeDTO {
	static let mockChillActivityType: ActivityTypeDTO = ActivityTypeDTO(
		id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890") ?? UUID(),
		title: "Chill", icon: "🛋️", associatedFriends: [BaseUserDTO.danielLee, BaseUserDTO.danielAgapov],
		orderNum: 0, isPinned: false
	)
	static let mockFoodActivityType: ActivityTypeDTO = ActivityTypeDTO(
		id: UUID(uuidString: "B2C3D4E5-F678-9012-BCDE-F12345678901") ?? UUID(),
		title: "Food", icon: "🍽️",
		associatedFriends: [BaseUserDTO.danielLee, BaseUserDTO.haley, BaseUserDTO.haley], orderNum: 1, isPinned: true)
	static let mockActiveActivityType: ActivityTypeDTO = ActivityTypeDTO(
		id: UUID(uuidString: "C3D4E5F6-7890-1234-CDEF-123456789012") ?? UUID(),
		title: "Active", icon: "🏃",
		associatedFriends: [BaseUserDTO.haley, BaseUserDTO.danielLee, BaseUserDTO.haley, BaseUserDTO.danielLee],
		orderNum: 2, isPinned: false)
	static let mockStudyActivityType: ActivityTypeDTO = ActivityTypeDTO(
		id: UUID(uuidString: "D4E5F678-9012-3456-DEF1-234567890123") ?? UUID(),
		title: "Study", icon: "✏️", associatedFriends: BaseUserDTO.mockUsers, orderNum: 3, isPinned: false)

	/// Creates a new ActivityTypeDTO instance with default values for creating a new activity type
	static func createNew() -> ActivityTypeDTO {
		return ActivityTypeDTO(
			id: UUID(),
			title: "",
			icon: "⭐️",
			associatedFriends: [],
			orderNum: 0,
			ownerUserId: nil,
			isPinned: false
		)
	}
}
