import Foundation
import SwiftUI

// MARK: - Deep Link Types
enum DeepLinkType {
    case activity(UUID)
    case unknown
}

// MARK: - Deep Link Manager
class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    
    @Published var pendingDeepLink: DeepLinkType?
    @Published var shouldShowActivity = false
    @Published var activityToShow: UUID?
    
    private init() {}
    
    // MARK: - URL Handling
    func handleURL(_ url: URL) {
        print("🔗 DeepLinkManager: Handling incoming URL: \(url.absoluteString)")
        
        // Handle both custom URL schemes (spawn://) and Universal Links (https://)
        guard url.scheme == "spawn" || (url.scheme == "https" && url.host == "getspawn.com") else {
            print("❌ DeepLinkManager: Invalid URL scheme or host: \(url.scheme ?? "nil")://\(url.host ?? "nil")")
            return
        }
        
        let deepLink = parseURL(url)
        processPendingDeepLink(deepLink)
    }
    
    // MARK: - URL Parsing
    private func parseURL(_ url: URL) -> DeepLinkType {
        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        print("🔗 DeepLinkManager: Parsing URL - Scheme: \(url.scheme ?? "nil"), Host: \(host), Path components: \(pathComponents)")
        
        // Handle Universal Links: https://getspawn.com/activity/{activityId} or https://getspawn.com/invite/{activityId}
        if url.scheme == "https" && host == "getspawn.com" {
            return parseUniversalLink(pathComponents: pathComponents)
        }
        
        // Handle custom URL schemes: spawn://activity/{activityId} or spawn://invite/{activityId}
        if url.scheme == "spawn" {
            return parseCustomURLScheme(host: host, pathComponents: pathComponents)
        }
        
        print("❌ DeepLinkManager: Unknown URL format")
        return .unknown
    }
    
    private func parseUniversalLink(pathComponents: [String]) -> DeepLinkType {
        print("🔗 DeepLinkManager: Parsing Universal Link with path components: \(pathComponents)")
        
        // Universal Link format: /activity/{activityId}
        if pathComponents.count >= 2 && pathComponents[0] == "activity" {
            let activityIdString = pathComponents[1]
            
            if let activityId = UUID(uuidString: activityIdString) {
                print("✅ DeepLinkManager: Successfully parsed Universal Link activity ID: \(activityId)")
                return .activity(activityId)
            } else {
                print("❌ DeepLinkManager: Failed to parse Universal Link activity ID from: \(activityIdString)")
            }
        }
        
        print("❌ DeepLinkManager: Invalid Universal Link path format - expected /activity/{activityId}")
        return .unknown
    }
    
    private func parseCustomURLScheme(host: String, pathComponents: [String]) -> DeepLinkType {
        print("🔗 DeepLinkManager: Parsing custom URL scheme with host: \(host), path components: \(pathComponents)")
        
        // Custom URL scheme format: spawn://activity/{activityId}
        if host == "activity" {
            // Host-based format: spawn://activity/{activityId}
            let activityIdString = pathComponents.first
            
            if let activityIdString = activityIdString,
               let activityId = UUID(uuidString: activityIdString) {
                print("✅ DeepLinkManager: Successfully parsed custom URL scheme activity ID: \(activityId)")
                return .activity(activityId)
            } else {
                print("❌ DeepLinkManager: Failed to parse custom URL scheme activity ID from: \(activityIdString ?? "nil")")
            }
        } else if pathComponents.count >= 2 && pathComponents[0] == "activity" {
            // Path-based format: spawn://domain/activity/{activityId}
            let activityIdString = pathComponents[1]
            
            if let activityId = UUID(uuidString: activityIdString) {
                print("✅ DeepLinkManager: Successfully parsed custom URL scheme path activity ID: \(activityId)")
                return .activity(activityId)
            } else {
                print("❌ DeepLinkManager: Failed to parse custom URL scheme path activity ID from: \(activityIdString)")
            }
        }
        
        print("❌ DeepLinkManager: Invalid custom URL scheme format - expected spawn://activity/{activityId}")
        return .unknown
    }
    
    // MARK: - Deep Link Processing
    private func processPendingDeepLink(_ deepLink: DeepLinkType) {
        DispatchQueue.main.async {
            switch deepLink {
            case .activity(let activityId):
                print("🎯 DeepLinkManager: Processing activity deep link: \(activityId)")
                self.pendingDeepLink = deepLink
                self.activityToShow = activityId
                self.shouldShowActivity = true
                
                // Post notification for other parts of the app to listen to
                NotificationCenter.default.post(
                    name: .deepLinkActivityReceived,
                    object: nil,
                    userInfo: ["activityId": activityId]
                )
                
            case .unknown:
                print("❌ DeepLinkManager: Unknown deep link type, ignoring")
                self.pendingDeepLink = nil
                self.activityToShow = nil
                self.shouldShowActivity = false
            }
        }
    }
    
    // MARK: - State Management
    func clearPendingDeepLink() {
        DispatchQueue.main.async {
            print("🔗 DeepLinkManager: Clearing pending deep link")
            self.pendingDeepLink = nil
            self.activityToShow = nil
            self.shouldShowActivity = false
        }
    }
    
    func hasPendingDeepLink() -> Bool {
        return pendingDeepLink != nil
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let deepLinkActivityReceived = Notification.Name("deepLinkActivityReceived")
} 