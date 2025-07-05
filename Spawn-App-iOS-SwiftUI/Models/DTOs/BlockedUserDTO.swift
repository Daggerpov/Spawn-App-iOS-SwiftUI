import Foundation

struct BlockedUserDTO: Codable {
    let id: UUID
    let blockerId: UUID
    let blockedId: UUID
    let blockerUsername: String
    let blockedUsername: String
    let reason: String
} 