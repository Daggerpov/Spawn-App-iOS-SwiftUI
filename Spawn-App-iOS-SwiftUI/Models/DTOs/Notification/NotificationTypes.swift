import Foundation

/// Defines all notification types used in the app
enum NotificationType: String, Codable {
    /// Friend request notifications
    case friendRequest = "friendRequest"
    
    /// Event invite notifications
    case eventInvite = "eventInvite"
    
    /// Event update notifications
    case eventUpdate = "eventUpdate"
    
    /// Chat message notifications
    case chat = "chat"
    
    /// Welcome notification
    case welcome = "welcome"
}

/// Utility for building notification data
struct NotificationDataBuilder {
    /// Build notification data for a friend request
    static func friendRequest(senderId: UUID, requestId: UUID) -> [String: String] {
        return [
            "type": NotificationType.friendRequest.rawValue,
            "senderId": senderId.uuidString,
            "requestId": requestId.uuidString
        ]
    }
    
    /// Build notification data for an event invite
    static func eventInvite(eventId: UUID, eventName: String) -> [String: String] {
        return [
            "type": NotificationType.eventInvite.rawValue,
            "eventId": eventId.uuidString,
            "eventName": eventName
        ]
    }
    
    /// Build notification data for an event update
    static func eventUpdate(eventId: UUID, updateType: String) -> [String: String] {
        return [
            "type": NotificationType.eventUpdate.rawValue,
            "eventId": eventId.uuidString,
            "updateType": updateType
        ]
    }
    
    /// Build notification data for a chat message
    static func chatMessage(eventId: UUID, senderId: UUID) -> [String: String] {
        return [
            "type": NotificationType.chat.rawValue,
            "eventId": eventId.uuidString,
            "senderId": senderId.uuidString
        ]
    }
    
    /// Build notification data for a welcome message
    static func welcome() -> [String: String] {
        return [
            "type": NotificationType.welcome.rawValue
        ]
    }
} 