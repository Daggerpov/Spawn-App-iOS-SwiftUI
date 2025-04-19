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
                }
            }
            .tint(universalAccentColor)
            .accentColor(universalAccentColor)
        }
        .padding(.horizontal)
    }
}

// MARK: - Message Input Component
struct MessageInputView: View {
    @Binding var message: String
    @Binding var isFocused: Bool
    @FocusState private var textFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Message")
                .font(.headline)
                .foregroundColor(universalAccentColor)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $message)
                    .foregroundColor(universalAccentColor)
                    .scrollContentBackground(.hidden)
                    .background(Color.white)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .focused($textFieldFocused)
                    .onChange(of: textFieldFocused) { newValue in
                        isFocused = newValue
                    }
                    .onChange(of: isFocused) { newValue in
                        textFieldFocused = newValue
                    }
                    .onSubmit {
                        textFieldFocused = false
                    }
                
                if message.isEmpty && !textFieldFocused {
                    Text("Share your thoughts, report a bug, or suggest a feature...")
                        .foregroundColor(Color.gray)
                        .padding(.leading, 16)
                        .padding(.top, 16)
                        .allowsHitTesting(false)
                }
            }
            .onTapGesture {
                if !textFieldFocused {
                    textFieldFocused = true
                }
            }
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
           
            Spacer()
            
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
            Spacer()
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
    @State private var isTextFieldFocused: Bool = false
    
    let userId: UUID?
    let email: String?
    
    init(userId: UUID?, email: String?) {
        self.userId = userId
        self.email = email
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Feedback type selector
                    FeedbackTypeSelector(selectedType: $selectedType)
                        .padding(.top, 10)
                    
                    // Message input
                    MessageInputView(message: $message, isFocused: $isTextFieldFocused)
                    
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
                    .padding(.vertical, 10)
                    
                    // Success/Error message
                    FeedbackStatusView(
                        feedbackService: feedbackService,
                        onSuccess: { dismiss() }
                    )
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .onTapGesture {
                    if isTextFieldFocused {
                        isTextFieldFocused = false
                    }
                }
            }
            .navigationBarBackButtonHidden()
            .background(universalBackgroundColor.ignoresSafeArea())
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(universalBackgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Send Feedback")
                        .font(.headline)
                        .foregroundColor(universalAccentColor)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(universalAccentColor)
                    }
                }
            }
        }
        .accentColor(universalAccentColor) // Set global accent color for the navigation view
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

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    FeedbackView(userId: UUID(), email: "user@example.com")
} 
