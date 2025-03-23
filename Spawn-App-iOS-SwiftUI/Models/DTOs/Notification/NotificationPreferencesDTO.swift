import Foundation

/// Data transfer object for managing notification preferences
struct NotificationPreferencesDTO: Codable {
    /// Whether the user wants to receive friend request notifications
    let friendRequestsEnabled: Bool
    
    /// Whether the user wants to receive event invite notifications
    let eventInvitesEnabled: Bool
    
    /// Whether the user wants to receive event update notifications
    let eventUpdatesEnabled: Bool
    
    /// Whether the user wants to receive chat message notifications
    let chatMessagesEnabled: Bool
    
    /// The user ID associated with these preferences
    let userId: UUID
} 