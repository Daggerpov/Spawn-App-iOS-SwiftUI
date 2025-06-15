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
    
    
    init(id: UUID, title: String, icon: String, associatedFriends: [BaseUserDTO], orderNum: Int) {
        self.id = id
        self.title = title
        self.icon = icon
        self.associatedFriends = associatedFriends
        self.orderNum = orderNum
    }
}


extension ActivityTypeDTO {
    static var mockChillActivityType: ActivityTypeDTO = ActivityTypeDTO(
        id: UUID(),title: "Chill", icon: "🛋️", associatedFriends: [BaseUserDTO.danielLee, BaseUserDTO.jennifer], orderNum: 0
    )
    static var mockFoodActivityType: ActivityTypeDTO = ActivityTypeDTO(id: UUID(), title: "Food", icon: "🍽️", associatedFriends: [BaseUserDTO.danielLee, BaseUserDTO.michael, BaseUserDTO.haley], orderNum: 1)
    static var mockActiveActivityType: ActivityTypeDTO = ActivityTypeDTO(id: UUID(), title: "Active", icon: "🏃", associatedFriends: [BaseUserDTO.haley, BaseUserDTO.shannon, BaseUserDTO.michael, BaseUserDTO.danielLee], orderNum: 2)
    static var mockStudyActivityType: ActivityTypeDTO = ActivityTypeDTO(id: UUID(), title: "Study", icon: "✏️", associatedFriends: BaseUserDTO.mockUsers, orderNum: 3)
}
