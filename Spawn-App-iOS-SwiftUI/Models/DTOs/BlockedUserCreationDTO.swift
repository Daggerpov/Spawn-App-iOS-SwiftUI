import Foundation

struct BlockedUserCreationDTO: Codable {
    let blockerId: UUID
    let blockedId: UUID
    let reason: String
} 