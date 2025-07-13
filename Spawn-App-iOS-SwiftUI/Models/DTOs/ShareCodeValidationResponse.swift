import Foundation

struct ShareCodeValidationResponse: Codable {
    let shareCode: String
    let type: String
    let exists: Bool
    let expired: Bool
    let targetId: String?
} 