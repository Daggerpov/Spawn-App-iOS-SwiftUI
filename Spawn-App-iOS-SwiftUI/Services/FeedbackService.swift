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
            guard let url = URL(string: APIService.baseURL + "feedback") else {
                throw APIError.URLError
            }
            
            // Create feedback submission as dictionary
            var feedbackDict: [String: Any] = [
                "type": type.rawValue,
                "message": message
            ]
            
            // Add user ID if available
            if let userId = userId {
                feedbackDict["fromUserId"] = userId.uuidString
            }
            
            // Add image data if available (as base64 string)
            if let image = image {
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    let base64String = imageData.base64EncodedString()
                    feedbackDict["imageData"] = base64String
                    print("Including feedback image data of size: \(imageData.count) bytes")
                }
            }
            
            // Convert dictionary to JSON data
            guard let jsonData = try? JSONSerialization.data(withJSONObject: feedbackDict) else {
                throw APIError.invalidData
            }
            
            // Create and send the request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.failedHTTPRequest(description: "HTTP request failed")
            }
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                // Try to parse error message from response
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Error Response: \(errorJson)")
                } else if let errorString = String(data: data, encoding: .utf8) {
                    print("Error Response (non-JSON): \(errorString)")
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
    
    @MainActor
    private func setError(_ message: String) {
        isSubmitting = false
        errorMessage = message
    }
} 
