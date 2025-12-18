import Foundation

struct BlockedUserCreationDTO: Codable, Sendable {
	let blockerId: UUID
	let blockedId: UUID
	let reason: String
}
