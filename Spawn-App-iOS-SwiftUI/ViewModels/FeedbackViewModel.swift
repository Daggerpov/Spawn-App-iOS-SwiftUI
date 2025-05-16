//
//  FeedbackViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Claude on 2025-08-27.
//

import Foundation
import SwiftUI

class FeedbackViewModel: ObservableObject {
    // API Service injected via dependency injection
    private var apiService: IAPIService
    
    // Published properties that the view can observe
    @Published var isSubmitting = false
    @Published var successMessage: String?
    @Published var errorMessage: String?
    
    init(apiService: IAPIService = APIService()) {
        self.apiService = apiService
    }
    
    func submitFeedback(type: FeedbackType, message: String, userId: UUID? = nil, image: UIImage? = nil) async {
        guard !message.isEmpty else {
            await setError("Please enter a message")
            return
        }
        
        await MainActor.run {
            isSubmitting = true
            errorMessage = nil
            successMessage = nil
        }
        
        do {
            // Create the feedback endpoint URL
            guard let url = URL(string: APIService.baseURL + "feedback") else {
                throw APIError.URLError
            }
            
            // Create feedback data model
            var feedback = FeedbackSubmissionDTO(
                type: type.rawValue,
                message: message,
                fromUserId: userId?.uuidString
            )
            
            // Handle image using the resize helper
            if let image = image {
                let resizedImage = resizeImageIfNeeded(image, maxDimension: 1024)
                if let imageData = resizedImage.jpegData(compressionQuality: 0.7) {
                    let base64String = imageData.base64EncodedString()
                    feedback.imageData = base64String
                    print("Including feedback image data of size: \(imageData.count) bytes")
                }
            }
            
            // Use apiService.sendData to handle the POST request
            let _: FeedbackSubmissionDTO? = try await apiService.sendData(feedback, to: url, parameters: nil)
            
            await MainActor.run {
                isSubmitting = false
                successMessage = "Thank you for your feedback!"
            }
        } catch {
            await setError("Failed to submit feedback: \(error.localizedDescription)")
        }
    }
    
    // Helper method to resize images
    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalSize = image.size
        
        // Check if resizing is needed
        if originalSize.width <= maxDimension && originalSize.height <= maxDimension {
            return image
        }
        
        // Calculate the new size while preserving aspect ratio
        var newSize: CGSize
        if originalSize.width > originalSize.height {
            let ratio = maxDimension / originalSize.width
            newSize = CGSize(width: maxDimension, height: originalSize.height * ratio)
        } else {
            let ratio = maxDimension / originalSize.height
            newSize = CGSize(width: originalSize.width * ratio, height: maxDimension)
        }
        
        // Render the image at the new size
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    @MainActor
    private func setError(_ message: String) {
        isSubmitting = false
        errorMessage = message
    }
}

// DTO for submitting feedback
struct FeedbackSubmissionDTO: Codable {
    let type: String
    let message: String
    let fromUserId: String?
    var imageData: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case message
        case fromUserId
        case imageData
    }
} 