import Foundation

struct UserProfileInfoDTO: Codable {
    let userId: UUID
    let name: String
    let username: String
    let bio: String?
    let profilePicture: String?
    let dateCreated: Date
} 