import Foundation

struct UserSocialMediaDTO: Codable {
    var id: UUID
    var userId: UUID
    var whatsappLink: String?
    var instagramLink: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case whatsappLink
        case instagramLink
    }
}

