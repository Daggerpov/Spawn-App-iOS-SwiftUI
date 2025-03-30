//
//  FeedbackView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Claude on 2025-02-18.
//

import SwiftUI
import PhotosUI

// MARK: - Feedback Type Selector Component
struct FeedbackTypeSelector: View {
    @Binding var selectedType: FeedbackType
    
    var body: some View {
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
        }
        .padding(.horizontal)
    }
}

// MARK: - Message Input Component
struct MessageInputView: View {
    @Binding var message: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Message")
                .font(.headline)
                .foregroundColor(universalAccentColor)
            
            TextEditor(text: $message)
                .scrollContentBackground(.hidden) // This hides the default background
                .background(Color.white)
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
                                    .foregroundColor(universalAccentColor)
                                    .padding(.leading, 16)
                                    .padding(.top, 16)
                                Spacer()
                            }
                        }
                    }
                )
        }
        .padding(.horizontal)
    }
}

// MARK: - Image Picker Component
struct ImagePickerView: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Attach Image (Optional)")
                .font(.headline)
                .foregroundColor(universalAccentColor)
            
            HStack {
                Spacer()
                
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 150)
                        .cornerRadius(8)
                    
                    Button(action: {
                        self.selectedImage = nil
                        self.selectedItem = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 24))
                            .background(Circle().fill(Color.white))
                    }
                    .offset(x: -10, y: -60)
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                            Text("Select Image")
                        }
                        .foregroundColor(universalAccentColor)
                        .frame(maxWidth: 150, maxHeight: 100)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Submit Button Component
struct SubmitButtonView: View {
    @ObservedObject var feedbackService: FeedbackService
    var message: String
    var onSubmit: () -> Void
    
    var body: some View {
        Button(action: onSubmit) {
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
    }
}

// MARK: - Feedback Status Component
struct FeedbackStatusView: View {
    @ObservedObject var feedbackService: FeedbackService
    var onSuccess: () -> Void
    
    var body: some View {
        VStack {
            if let successMessage = feedbackService.successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .padding()
                    .onAppear {
                        // Dismiss after showing success message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onSuccess()
                        }
                    }
            }
            
            if let errorMessage = feedbackService.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}

// MARK: - Main Feedback View
struct FeedbackView: View {
    @StateObject private var feedbackService = FeedbackService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: FeedbackType = .GENERAL_FEEDBACK
    @State private var message: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
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
                FeedbackTypeSelector(selectedType: $selectedType)
                
                // Message input
                MessageInputView(message: $message)
                
                // Image picker
                ImagePickerView(selectedItem: $selectedItem, selectedImage: $selectedImage)
                    .onChange(of: selectedItem) { newItem in
                        loadTransferable(from: newItem)
                    }
                
                // Submit button
                SubmitButtonView(
                    feedbackService: feedbackService,
                    message: message,
                    onSubmit: {
                        Task {
                            await feedbackService.submitFeedback(
                                type: selectedType,
                                message: message,
                                userId: userId,
                                image: selectedImage
                            )
                        }
                    }
                )
                
                // Success/Error message
                FeedbackStatusView(
                    feedbackService: feedbackService,
                    onSuccess: { dismiss() }
                )
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationBarTitle("Send Feedback", displayMode: .inline)
            .background(universalBackgroundColor.edgesIgnoringSafeArea(.all))
        }
    }
    
    private func loadTransferable(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                        if let unwrappedData = data {
                            if let image = UIImage(data: unwrappedData) {
                                self.selectedImage = image
                                
                            }
                        }
                case .failure(let error):
                    print("Photo picker error: \(error)")
                }
            }
        }
    }
}

#Preview {
    FeedbackView(userId: UUID(), email: "user@example.com")
} 
