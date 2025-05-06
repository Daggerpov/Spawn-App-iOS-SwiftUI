import Foundation

struct UserSocialMediaDTO: Codable {
    var id: UUID
    var userId: UUID
    var whatsappLink: String?
    var instagramLink: String?
}

