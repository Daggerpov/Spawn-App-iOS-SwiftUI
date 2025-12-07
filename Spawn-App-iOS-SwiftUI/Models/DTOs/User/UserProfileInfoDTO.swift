import Foundation

struct UserProfileInfoDTO: Codable, Sendable {
	let userId: UUID
	let name: String
	let username: String
	let bio: String?
	let profilePicture: String?
	let dateCreated: Date?
}
