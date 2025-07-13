import SwiftUI
import Combine

@MainActor
class InAppNotificationManager: ObservableObject {
    static let shared = InAppNotificationManager()
    
    @Published var isShowingNotification = false
    @Published var currentNotification: InAppNotificationData?
    
    private var notificationTimer: Timer?
    private var dismissWorkItem: DispatchWorkItem?
    
    private init() {}
    
    /// Show an in-app notification
    /// - Parameters:
    ///   - title: The notification title
    ///   - message: The notification message
    ///   - type: The notification type
    ///   - duration: How long to show the notification (default: 4 seconds)
    func showNotification(
        title: String,
        message: String,
        type: NotificationType,
        duration: TimeInterval = 4.0
    ) {
        // Cancel any existing notification
        dismissNotification()
        
        // Set new notification data
        currentNotification = InAppNotificationData(
            title: title,
            message: message,
            type: type
        )
        
        // Show notification with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingNotification = true
        }
        
        // Auto-dismiss after duration
        dismissWorkItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.dismissNotification()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: dismissWorkItem!)
    }
    
    /// Dismiss the current notification
    func dismissNotification() {
        // Cancel any pending dismiss work
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        
        // Hide notification with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingNotification = false
        }
        
        // Clear notification data after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentNotification = nil
        }
    }
    
    /// Show notification from push notification payload
    /// - Parameter userInfo: The push notification payload
    func showNotificationFromPushData(_ userInfo: [AnyHashable: Any]) {
        guard let typeString = userInfo["type"] as? String,
              let notificationType = NotificationType(rawValue: typeString) else {
            print("[IN-APP NOTIFICATION] Invalid notification type in payload")
            return
        }
        
        let title = extractTitle(from: userInfo, type: notificationType)
        let message = extractMessage(from: userInfo, type: notificationType)
        
        showNotification(title: title, message: message, type: notificationType)
    }
    
    // MARK: - Private Helpers
    
    private func extractTitle(from userInfo: [AnyHashable: Any], type: NotificationType) -> String {
        switch type {
        case .friendRequest:
            return "Friend Request"
        case .activityInvite:
            return "Activity Invite"
        case .activityUpdate:
            return "Activity Update"
        case .chat:
            return "New Message"
        case .welcome:
            return "Welcome!"
        case .error:
            return "Error"
        case .success:
            return "Success"
        }
    }
    
    private func extractMessage(from userInfo: [AnyHashable: Any], type: NotificationType) -> String {
        switch type {
        case .friendRequest:
            if let senderName = userInfo["senderName"] as? String {
                return "\(senderName) wants to be your friend"
            }
            return "You have a new friend request"
            
        case .activityInvite:
            if let activityName = userInfo["activityName"] as? String {
                return "You're invited to \(activityName)"
            }
            return "You have a new activity invitation"
            
        case .activityUpdate:
            if let activityName = userInfo["activityName"] as? String,
               let updateType = userInfo["updateType"] as? String {
                return "\(activityName) has been \(updateType)"
            } else if let activityName = userInfo["activityName"] as? String {
                return "\(activityName) has been updated"
            }
            return "An activity has been updated"
            
        case .chat:
            if let activityName = userInfo["activityName"] as? String,
               let senderName = userInfo["senderName"] as? String {
                return "\(senderName) sent a message in \(activityName)"
            } else if let senderName = userInfo["senderName"] as? String {
                return "\(senderName) sent you a message"
            }
            return "You have a new message"
            
        case .welcome:
            return "Welcome to Spawn! Start connecting with friends."
            
        case .error:
            if let errorMessage = userInfo["errorMessage"] as? String {
                return errorMessage
            }
            return "Something went wrong. Please try again."
            
        case .success:
            if let successMessage = userInfo["successMessage"] as? String {
                return successMessage
            }
            return "Action completed successfully"
        }
    }
}

// MARK: - Data Model

struct InAppNotificationData {
    let title: String
    let message: String
    let type: NotificationType
} 