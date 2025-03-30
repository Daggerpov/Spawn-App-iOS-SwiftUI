//
//  FeedbackService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Claude on 2025-02-18.
//

import Foundation
import SwiftUI

class FeedbackService: ObservableObject {
    private var apiService: IAPIService
    
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
            // Create the CreateFeedbackSubmissionDTO to exactly match the backend
            let feedbackDTO = CreateFeedbackSubmissionDTO(
                type: type,
                fromUserId: userId,
                message: message,
                image: image != nil ? resizeImageIfNeeded(image!, maxDimension: 1024) : nil
            )
            
            guard let url = URL(string: APIService.baseURL + "feedback") else {
                throw APIError.URLError
            }
            
            // Use the apiService's sendData method which properly handles serialization
            let _: CreateFeedbackSubmissionDTO? = try await apiService.sendData(
                feedbackDTO,
                to: url,
                parameters: nil
            )
            
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
