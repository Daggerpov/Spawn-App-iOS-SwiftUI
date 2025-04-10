import Foundation
import UIKit

struct CreateFeedbackSubmissionDTO: Codable {
    let type: FeedbackType
    let fromUserId: UUID?
    let message: String
    let imageData: Data?
    
    init(type: FeedbackType, fromUserId: UUID? = nil, message: String, image: UIImage? = nil) {
        self.type = type
        self.fromUserId = fromUserId
        self.message = message
        self.imageData = image?.jpegData(compressionQuality: 0.7)
    }
} 