//
//  ActivityTypeDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/31/25.
//
import Foundation

class ActivityTypeDTO: Identifiable, Codable {
    var id: UUID
    var title: String
    var icon: String
    var associatedFriends: [BaseUserDTO]
    var orderNum: Int
    var isPinned: Bool
    
    
    init(id: UUID, title: String, icon: String, associatedFriends: [BaseUserDTO], orderNum: Int, isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.icon = icon
        self.associatedFriends = associatedFriends
        self.orderNum = orderNum
        self.isPinned = isPinned
    }
}

// DTO for updating pin status
struct ActivityTypePinUpdateDTO: Codable {
    let activityTypeId: UUID
    let isPinned: Bool
}

extension ActivityTypeDTO {
    static var mockChillActivityType: ActivityTypeDTO = ActivityTypeDTO(
        id: UUID(),title: "Chill", icon: "🛋️", associatedFriends: [BaseUserDTO.danielLee, BaseUserDTO.jennifer], orderNum: 0, isPinned: false
    )
    static var mockFoodActivityType: ActivityTypeDTO = ActivityTypeDTO(id: UUID(), title: "Food", icon: "🍽️", associatedFriends: [BaseUserDTO.danielLee, BaseUserDTO.michael, BaseUserDTO.haley], orderNum: 1, isPinned: true)
    static var mockActiveActivityType: ActivityTypeDTO = ActivityTypeDTO(id: UUID(), title: "Active", icon: "🏃", associatedFriends: [BaseUserDTO.haley, BaseUserDTO.shannon, BaseUserDTO.michael, BaseUserDTO.danielLee], orderNum: 2, isPinned: false)
    static var mockStudyActivityType: ActivityTypeDTO = ActivityTypeDTO(id: UUID(), title: "Study", icon: "✏️", associatedFriends: BaseUserDTO.mockUsers, orderNum: 3, isPinned: false)
}
