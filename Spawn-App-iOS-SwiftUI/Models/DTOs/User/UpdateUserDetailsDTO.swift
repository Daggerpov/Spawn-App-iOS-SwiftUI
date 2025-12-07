import Foundation

struct UpdateUserDetailsDTO: Codable, Sendable {
	let id: String  // UUID as String
	let username: String
	let phoneNumber: String
	let password: String?
}
