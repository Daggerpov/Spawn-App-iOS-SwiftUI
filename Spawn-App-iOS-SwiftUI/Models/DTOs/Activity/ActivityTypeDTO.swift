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
