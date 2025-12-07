import Foundation

struct UserStatsDTO: Codable, Sendable {
	var peopleMet: Int
	var spawnsMade: Int
	var spawnsJoined: Int
}
