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
            // Create URL
            guard let url = URL(string: APIService.baseURL + "feedback") else {
                throw APIError.URLError
            }
            
            // Create feedback data as dictionary with manual handling for image
            var feedbackDict: [String: Any] = [
                "type": type.rawValue,
                "message": message,
            ]
            
            // Add userId if available
            if let userId = userId {
                feedbackDict["fromUserId"] = userId.uuidString
            }
            
            // Handle image the same way as in createUser
            if let image = image {
                let resizedImage = resizeImageIfNeeded(image, maxDimension: 1024)
                if let imageData = resizedImage.jpegData(compressionQuality: 0.7) {
                    let base64String = imageData.base64EncodedString()
                    feedbackDict["imageData"] = base64String
                    print("Including feedback image data of size: \(imageData.count) bytes")
                }
            }
            
            // Convert dictionary to JSON data
            guard let jsonData = try? JSONSerialization.data(withJSONObject: feedbackDict) else {
                throw APIError.invalidData
            }
            
            // Create request manually
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            // Send the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.failedHTTPRequest(description: "HTTP request failed")
            }
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                // Try to parse error message
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorJson["message"] as? String {
                    print("Error response: \(errorMessage)")
                } else if let errorString = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorString)")
                }
                
                throw APIError.invalidStatusCode(statusCode: httpResponse.statusCode)
            }
            
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
