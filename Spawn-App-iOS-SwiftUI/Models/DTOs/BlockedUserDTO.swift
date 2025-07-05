import Foundation

struct BlockedUserDTO: Codable {
    let id: UUID
    let blockerId: UUID
    let blockedId: UUID
    let blockerUsername: String
    let blockedUsername: String
    let blockerName: String
    let blockedName: String
    let blockerProfilePicture: String?
    let blockedProfilePicture: String?
    let reason: String
    
    // Keep the old constructor for backward compatibility
    init(id: UUID, blockerId: UUID, blockedId: UUID, blockerUsername: String, blockedUsername: String, reason: String) {
        self.id = id
        self.blockerId = blockerId
        self.blockedId = blockedId
        self.blockerUsername = blockerUsername
        self.blockedUsername = blockedUsername
        self.blockerName = blockedUsername // Fallback to username
        self.blockedName = blockedUsername // Fallback to username
        self.blockerProfilePicture = nil
        self.blockedProfilePicture = nil
        self.reason = reason
    }
} 