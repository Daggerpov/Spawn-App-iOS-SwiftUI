//
//  FeedbackView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Claude on 2025-02-18.
//

import SwiftUI

struct FeedbackView: View {
    @StateObject private var feedbackService = FeedbackService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: FeedbackType = .GENERAL_FEEDBACK
    @State private var message: String = ""
    
    let userId: UUID?
    let email: String?
    
    init(userId: UUID?, email: String?) {
        self.userId = userId
        self.email = email
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Feedback type selector
                HStack(spacing: 10) {
                    Text("Feedback Type")
                        .font(.headline)
                        .foregroundColor(universalAccentColor)
                    
                    Picker("", selection: $selectedType) {
                        ForEach(FeedbackType.allCases) { type in
                            VStack {
                                Image(systemName: type.iconName)
                                Text(type.displayName)
                            }
                            .tag(type)
                            .foregroundColor(universalAccentColor)
                        }
                    }
//                    .pickerStyle(())
                }
                .padding(.horizontal)
                
                // Message input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Message")
                        .font(.headline)
                        .foregroundColor(universalAccentColor)
                    
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if message.isEmpty {
                                    HStack(alignment: .top) {
                                        Text("Share your thoughts, report a bug, or suggest a feature...")
                                            .foregroundColor(.gray.opacity(0.7))
                                            .padding(.leading, 16)
                                            .padding(.top, 16)
                                        Spacer()
                                    }
                                }
                            }
                        )
                }
                .padding(.horizontal)
                
                // Submit button
                Button(action: {
                    Task {
                        await feedbackService.submitFeedback(
                            type: selectedType,
                            message: message,
                            userId: userId,
                            email: email
                        )
                    }
                }) {
                    HStack {
                        if feedbackService.isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 5)
                        }
                        Text(feedbackService.isSubmitting ? "Submitting..." : "Submit Feedback")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(universalAccentColor)
                    .cornerRadius(10)
                }
                .disabled(message.isEmpty || feedbackService.isSubmitting)
                .padding(.horizontal)
                
                // Success/Error message
                if let successMessage = feedbackService.successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .padding()
                        .onAppear {
                            // Dismiss after showing success message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }
                }
                
                if let errorMessage = feedbackService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationBarTitle("Send Feedback", displayMode: .inline)
            .background(universalBackgroundColor.edgesIgnoringSafeArea(.all))
        }
    }
}

#Preview {
    FeedbackView(userId: UUID(), email: "user@example.com")
} 
