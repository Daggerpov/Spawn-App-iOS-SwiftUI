//
//  ActivityTypeDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/31/25.
//
import Foundation

class ActivityTypeDTO: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var icon: String
    var associatedFriends: [BaseUserDTO]
    var orderNum: Int
    var ownerUserId: UUID?
    var isPinned: Bool
    
    
    init(id: UUID, title: String, icon: String, associatedFriends: [BaseUserDTO], orderNum: Int, ownerUserId: UUID? = nil, isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.icon = icon
        self.associatedFriends = associatedFriends
        self.orderNum = orderNum
        self.ownerUserId = ownerUserId
        self.isPinned = isPinned
    }
    
    // MARK: - Equatable
    static func == (lhs: ActivityTypeDTO, rhs: ActivityTypeDTO) -> Bool {
        return lhs.id == rhs.id
    }
}

// DTO for batch updating activity types
struct BatchActivityTypeUpdateDTO: Codable {
    let updatedActivityTypes: [ActivityTypeDTO]
    let deletedActivityTypeIds: [UUID]
    
    init(updatedActivityTypes: [ActivityTypeDTO] = [], deletedActivityTypeIds: [UUID] = []) {
        self.updatedActivityTypes = updatedActivityTypes
        self.deletedActivityTypeIds = deletedActivityTypeIds
    }
}

extension ActivityTypeDTO {
    static var mockChillActivityType: ActivityTypeDTO = ActivityTypeDTO(
        id: UUID(), title: "Chill", icon: "🛋️", associatedFriends: [BaseUserDTO.danielLee, BaseUserDTO.danielAgapov], orderNum: 0, isPinned: false
    )
    static var mockFoodActivityType: ActivityTypeDTO = ActivityTypeDTO(id: UUID(), title: "Food", icon: "🍽️", associatedFriends: [BaseUserDTO.danielLee, BaseUserDTO.haley, BaseUserDTO.haley], orderNum: 1, isPinned: true)
    static var mockActiveActivityType: ActivityTypeDTO = ActivityTypeDTO(id: UUID(), title: "Active", icon: "🏃", associatedFriends: [BaseUserDTO.haley, BaseUserDTO.danielLee, BaseUserDTO.haley, BaseUserDTO.danielLee], orderNum: 2, isPinned: false)
    static var mockStudyActivityType: ActivityTypeDTO = ActivityTypeDTO(id: UUID(), title: "Study", icon: "✏️", associatedFriends: BaseUserDTO.mockUsers, orderNum: 3, isPinned: false)
    
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
