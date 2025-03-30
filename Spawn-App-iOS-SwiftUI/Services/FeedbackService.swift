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
            // Create feedback submission DTO with image data
            let feedbackDTO = CreateFeedbackSubmissionDTO(
                type: type,
                fromUserId: userId,
                message: message,
                image: image
            )
            
            // Send to appropriate endpoint
            if image != nil {
                try await submitWithImage(feedback: feedbackDTO)
            } else {
                try await submitWithoutImage(feedback: feedbackDTO)
            }
            
            await MainActor.run {
                isSubmitting = false
                successMessage = "Thank you for your feedback!"
            }
        } catch {
            await setError("Failed to submit feedback: \(error.localizedDescription)")
        }
    }
    
    private func submitWithoutImage(feedback: CreateFeedbackSubmissionDTO) async throws {
        guard let url = URL(string: APIService.baseURL + "feedback") else {
            throw APIError.URLError
        }
        
        let _ = try await apiService.sendData(feedback, to: url, parameters: nil)
    }
    
    private func submitWithImage(feedback: CreateFeedbackSubmissionDTO) async throws {
        guard let url = URL(string: APIService.baseURL + "feedback") else {
            throw APIError.URLError
        }
        
        // Use sendData instead of multipart form data
        let _ = try await apiService.sendData(feedback, to: url, parameters: nil)
    }
    
    @MainActor
    private func setError(_ message: String) {
        isSubmitting = false
        errorMessage = message
    }
} 
