import Foundation

struct ServiceConstants {
    // MARK: - App Configuration
    struct URLs {
        // Base URL for API calls
        static let apiBase = "https://spawn-app-back-end-production.up.railway.app/api/v1/"
        
        // Base URL for sharing activities - updated to match deployed web app
        static let shareBase = "https://getspawn.com"
    }
    
    // MARK: - Share URL Generation
    static func generateActivityShareURL(for activityId: UUID) -> URL {
        return URL(string: "\(URLs.shareBase)/activity/\(activityId.uuidString)")!
    }
} 
