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
        // First try to get a share code from the backend
        // For now, fall back to UUID-based sharing until share codes are implemented
        guard let url = URL(string: "\(URLs.shareBase)/activity/\(activityId.uuidString)") else {
            return URL(string: "https://spawnapp.com")!
        }
        return url
    }
    
    static func generateProfileShareURL(for userId: UUID) -> URL {
        // First try to get a share code from the backend
        // For now, fall back to UUID-based sharing until share codes are implemented
        guard let url = URL(string: "\(URLs.shareBase)/profile/\(userId.uuidString)") else {
            return URL(string: "https://spawnapp.com")!
        }
        return url
    }
    
    // MARK: - Share Code Generation
    static func generateActivityShareCodeURL(for activityId: UUID, completion: @escaping (URL?) -> Void) {
        // Generate share code via backend API
        let urlString = "\(URLs.apiBase)share/activity/\(activityId.uuidString)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let shareCode = json["shareCode"] as? String else {
                // Fall back to UUID-based URL if share code generation fails
                let fallbackUrl = URL(string: "\(URLs.shareBase)/activity/\(activityId.uuidString)")
                completion(fallbackUrl)
                return
            }
            
            let shareUrl = URL(string: "\(URLs.shareBase)/activity/\(shareCode)")
            completion(shareUrl)
        }.resume()
    }
    
    static func generateProfileShareCodeURL(for userId: UUID, completion: @escaping (URL?) -> Void) {
        // Generate share code via backend API
        let urlString = "\(URLs.apiBase)share/profile/\(userId.uuidString)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let shareCode = json["shareCode"] as? String else {
                // Fall back to UUID-based URL if share code generation fails
                let fallbackUrl = URL(string: "\(URLs.shareBase)/profile/\(userId.uuidString)")
                completion(fallbackUrl)
                return
            }
            
            let shareUrl = URL(string: "\(URLs.shareBase)/profile/\(shareCode)")
            completion(shareUrl)
        }.resume()
    }
} 
