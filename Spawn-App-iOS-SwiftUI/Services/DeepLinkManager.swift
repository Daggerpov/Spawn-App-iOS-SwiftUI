import Foundation
import SwiftUI

// MARK: - Deep Link Types
enum DeepLinkType {
    case activity(UUID)
    case profile(UUID)
    case unknown
}

// MARK: - Deep Link Manager
class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    
    @Published var pendingDeepLink: DeepLinkType?
    @Published var shouldShowActivity = false
    @Published var activityToShow: UUID?
    @Published var shouldShowProfile = false
    @Published var profileToShow: UUID?
    
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
        
        // Handle Universal Links: https://getspawn.com/activity/{activityId} or https://getspawn.com/profile/{profileId}
        if url.scheme == "https" && host == "getspawn.com" {
            return parseUniversalLink(pathComponents: pathComponents)
        }
        
        // Handle custom URL schemes: spawn://activity/{activityId} or spawn://profile/{profileId}
        if url.scheme == "spawn" {
            return parseCustomURLScheme(host: host, pathComponents: pathComponents)
        }
        
        print("❌ DeepLinkManager: Unknown URL format")
        return .unknown
    }
    
    private func parseUniversalLink(pathComponents: [String]) -> DeepLinkType {
        print("🔗 DeepLinkManager: Parsing Universal Link with path components: \(pathComponents)")
        
        // Universal Link format: /activity/{activityId} or /profile/{profileId}
        if pathComponents.count >= 2 {
            let type = pathComponents[0]
            let idString = pathComponents[1]
            
            if type == "activity" {
                if let activityId = UUID(uuidString: idString) {
                    print("✅ DeepLinkManager: Successfully parsed Universal Link activity ID: \(activityId)")
                    return .activity(activityId)
                } else {
                    print("❌ DeepLinkManager: Failed to parse Universal Link activity ID from: \(idString)")
                }
            } else if type == "profile" {
                if let profileId = UUID(uuidString: idString) {
                    print("✅ DeepLinkManager: Successfully parsed Universal Link profile ID: \(profileId)")
                    return .profile(profileId)
                } else {
                    print("❌ DeepLinkManager: Failed to parse Universal Link profile ID from: \(idString)")
                }
            }
        }
        
        print("❌ DeepLinkManager: Invalid Universal Link path format - expected /activity/{activityId} or /profile/{profileId}")
        return .unknown
    }
    
    private func parseCustomURLScheme(host: String, pathComponents: [String]) -> DeepLinkType {
        print("🔗 DeepLinkManager: Parsing custom URL scheme with host: \(host), path components: \(pathComponents)")
        
        // Custom URL scheme format: spawn://activity/{activityId} or spawn://profile/{profileId}
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
        } else if host == "profile" {
            // Host-based format: spawn://profile/{profileId}
            let profileIdString = pathComponents.first
            
            if let profileIdString = profileIdString,
               let profileId = UUID(uuidString: profileIdString) {
                print("✅ DeepLinkManager: Successfully parsed custom URL scheme profile ID: \(profileId)")
                return .profile(profileId)
            } else {
                print("❌ DeepLinkManager: Failed to parse custom URL scheme profile ID from: \(profileIdString ?? "nil")")
            }
        } else if pathComponents.count >= 2 {
            let type = pathComponents[0]
            let idString = pathComponents[1]
            
            if type == "activity" {
                if let activityId = UUID(uuidString: idString) {
                    print("✅ DeepLinkManager: Successfully parsed custom URL scheme path activity ID: \(activityId)")
                    return .activity(activityId)
                } else {
                    print("❌ DeepLinkManager: Failed to parse custom URL scheme path activity ID from: \(idString)")
                }
            } else if type == "profile" {
                if let profileId = UUID(uuidString: idString) {
                    print("✅ DeepLinkManager: Successfully parsed custom URL scheme path profile ID: \(profileId)")
                    return .profile(profileId)
                } else {
                    print("❌ DeepLinkManager: Failed to parse custom URL scheme path profile ID from: \(idString)")
                }
            }
        }
        
        print("❌ DeepLinkManager: Invalid custom URL scheme format - expected spawn://activity/{activityId} or spawn://profile/{profileId}")
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
                
            case .profile(let profileId):
                print("🎯 DeepLinkManager: Processing profile deep link: \(profileId)")
                self.pendingDeepLink = deepLink
                self.profileToShow = profileId
                self.shouldShowProfile = true
                
                // Post notification for other parts of the app to listen to
                NotificationCenter.default.post(
                    name: .deepLinkProfileReceived,
                    object: nil,
                    userInfo: ["profileId": profileId]
                )
                
            case .unknown:
                print("❌ DeepLinkManager: Unknown deep link type, ignoring")
                self.pendingDeepLink = nil
                self.activityToShow = nil
                self.shouldShowActivity = false
                self.profileToShow = nil
                self.shouldShowProfile = false
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
            self.profileToShow = nil
            self.shouldShowProfile = false
        }
    }
    
    func hasPendingDeepLink() -> Bool {
        return pendingDeepLink != nil
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let deepLinkActivityReceived = Notification.Name("deepLinkActivityReceived")
    static let deepLinkProfileReceived = Notification.Name("deepLinkProfileReceived")
} 