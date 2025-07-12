import Foundation

/// Defines all notification types used in the app
enum NotificationType: String, Codable {
    /// Friend request notifications
    case friendRequest = "friendRequest"
    
    /// Activity invite notifications
    case activityInvite = "activityInvite"
    
    /// Activity update notifications
    case activityUpdate = "activityUpdate"
    
    /// Chat message notifications
    case chat = "chat"
    
    /// Welcome notification
    case welcome = "welcome"
    
    /// Error notifications
    case error = "error"
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
    
    /// Build notification data for an activity invite
    static func activityInvite(activityId: UUID, activityName: String) -> [String: String] {
        return [
            "type": NotificationType.activityInvite.rawValue,
            "activityId": activityId.uuidString,
            "activityName": activityName
        ]
    }
    
    /// Build notification data for an activity update
    static func activityUpdate(activityId: UUID, updateType: String) -> [String: String] {
        return [
            "type": NotificationType.activityUpdate.rawValue,
            "activityId": activityId.uuidString,
            "updateType": updateType
        ]
    }
    
    /// Build notification data for a chat message
    static func chatMessage(activityId: UUID, senderId: UUID) -> [String: String] {
        return [
            "type": NotificationType.chat.rawValue,
            "activityId": activityId.uuidString,
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