import Foundation

struct UserSocialMediaDTO: Codable, Equatable {
    var id: UUID
    var userId: UUID
    var whatsappLink: String?
    var instagramLink: String?
    
    // Add computed properties for the raw values
    var whatsappNumber: String? {
        guard let whatsappLink = whatsappLink, !whatsappLink.isEmpty else { return nil }
        
        // Extract phone number from whatsapp link (https://wa.me/123456789)
        if whatsappLink.contains("wa.me/") {
            return whatsappLink.components(separatedBy: "wa.me/").last
        }
        return whatsappLink
    }
    
    var instagramUsername: String? {
        guard let instagramLink = instagramLink, !instagramLink.isEmpty else { return nil }
        
        // Extract username from instagram link (https://www.instagram.com/username)
        if instagramLink.contains("instagram.com/") {
            let username = instagramLink.components(separatedBy: "instagram.com/").last?.components(separatedBy: "/").first
            return username
        }
        return instagramLink
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case whatsappLink
        case instagramLink
    }
}

