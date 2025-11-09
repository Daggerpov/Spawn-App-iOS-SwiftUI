import Foundation

struct UpdateUserDetailsDTO: Codable {
	let id: String  // UUID as String
	let username: String
	let phoneNumber: String
	let password: String?
}
