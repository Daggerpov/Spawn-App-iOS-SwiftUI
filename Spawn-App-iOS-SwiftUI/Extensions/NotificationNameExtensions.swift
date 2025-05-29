import Foundation

extension Notification.Name {
    // Notification sent when user successfully logs in
    static let userDidLogin = Notification.Name("userDidLogin")
    
    // Notification sent when user logs out
    static let userDidLogout = Notification.Name("userDidLogout")
    
    // Notification for activity creation
    static let activityCreated = Notification.Name("activityCreated")
}
