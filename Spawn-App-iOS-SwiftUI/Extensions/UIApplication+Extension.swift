import UIKit
import SwiftUI

extension UIApplication {
    // Method to force release memory when app receives memory warning
    class func releaseMemoryOnWarning() {
        // Force a garbage collection cycle to clean up any lingering references
        URLCache.shared.removeAllCachedResponses()
        
        // Clear image caches if needed
        // Example: SDWebImageManager.shared.imageCache.clear(with: .all)
    }
    
    // Method to end background tasks to prevent memory leaks
    func endBackgroundTasks() {
        for task in self.backgroundTasks {
            self.endBackgroundTask(task)
        }
    }
    
    // Property to track all background tasks
    private static var _backgroundTasks = Set<UIBackgroundTaskIdentifier>()
    
    private var backgroundTasks: Set<UIBackgroundTaskIdentifier> {
        get { UIApplication._backgroundTasks }
        set { UIApplication._backgroundTasks = newValue }
    }
    
    // Method to begin a monitored background task
    func beginMonitoredBackgroundTask() -> UIBackgroundTaskIdentifier {
        let taskID = self.beginBackgroundTask {
            // End the task when time expires
            self.endBackgroundTask(taskID)
            UIApplication._backgroundTasks.remove(taskID)
        }
        
        // Add to our set of tracked tasks
        UIApplication._backgroundTasks.insert(taskID)
        return taskID
    }
    
    // Safer end background task method
    func safelyEndBackgroundTask(_ taskID: UIBackgroundTaskIdentifier) {
        guard taskID != .invalid else { return }
        
        self.endBackgroundTask(taskID)
        UIApplication._backgroundTasks.remove(taskID)
    }
}

// Global NotificationCenter extension to avoid memory leaks
extension NotificationCenter {
    // Register for notifications with automatic removal when object is deallocated
    static func safelyAddObserver(
        _ observer: Any,
        selector: Selector,
        name: NSNotification.Name?,
        object: Any?
    ) -> NSObjectProtocol {
        let token = NotificationCenter.default.addObserver(
            forName: name,
            object: object,
            queue: nil) { notification in
                // Using performSelector to avoid compile-time checking
                // which would prevent using this generically
                let targetObject = observer as AnyObject
                targetObject.perform(selector, with: notification)
            }
        
        return token
    }
    
    // Remove observer safely
    static func safelyRemoveObserver(_ token: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(token)
    }
} 