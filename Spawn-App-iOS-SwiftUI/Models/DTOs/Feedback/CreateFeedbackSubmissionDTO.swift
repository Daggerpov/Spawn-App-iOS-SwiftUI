import Foundation
import UIKit

struct CreateFeedbackSubmissionDTO: Codable {
    let type: FeedbackType
    let fromUserId: UUID?
    let message: String
    let imageData: String?
    
    init(type: FeedbackType, fromUserId: UUID? = nil, message: String, image: UIImage? = nil) {
        self.type = type
        self.fromUserId = fromUserId
        self.message = message
        
        // Use higher compression for better performance
        if let image = image {
            if let imageData = image.jpegData(compressionQuality: 0.5) {
                self.imageData = imageData.base64EncodedString()
                print("Image data size for feedback: \(imageData.count) bytes")
            } else {
                self.imageData = nil
            }
        } else {
            self.imageData = nil
        }
    }
} 