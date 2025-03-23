import Foundation

/// Data transfer object for registering a device token with the backend
struct DeviceTokenDTO: Codable {
    /// The device token from APNS
    let deviceToken: String
    
    /// The platform (iOS, Android, etc.)
    let platform: String
    
    /// The user ID associated with this device token
    let userId: UUID
} 