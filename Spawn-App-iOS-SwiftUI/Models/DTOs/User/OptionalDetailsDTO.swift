import Foundation

struct OptionalDetailsDTO: Codable, Sendable {
	let name: String
	let profilePictureData: Data?
}
