import Foundation

extension Notification.Name {
    // Notification sent when user successfully logs in
    static let userDidLogin = Notification.Name("userDidLogin")
    
    // Notification sent when user logs out
    static let userDidLogout = Notification.Name("userDidLogout")
    
    // Notifications for tag management
    static let friendsAddedToTag = Notification.Name("friendsAddedToTag")
    
    // Notification for event creation
    static let eventCreated = Notification.Name("eventCreated")
    
    // Notification for authentication failures
    static let userAuthenticationFailed = Notification.Name("userAuthenticationFailed")
}
