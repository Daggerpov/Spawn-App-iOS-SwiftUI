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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Message")
                .font(.headline)
                .foregroundColor(universalAccentColor)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $message)
                    .foregroundColor(universalAccentColor)
                    .scrollContentBackground(.hidden)
                    .background(universalBackgroundColor)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .focused($textFieldFocused)
                    .onChange(of: textFieldFocused) { _, newValue in
                        isFocused = newValue
                    }
                    .onChange(of: isFocused) { _, newValue in
                        textFieldFocused = newValue
                    }
                    .onSubmit {
                        textFieldFocused = false
                    }
                
                if message.isEmpty && !textFieldFocused {
                    Text("Share your thoughts, report a bug, or suggest a feature...")
                        .foregroundColor(universalPlaceHolderTextColor)
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
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
    }
}

// MARK: - Image Picker Component
struct ImagePickerView: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Attach Image (Optional)")
                .font(.headline)
                .foregroundColor(universalAccentColor)
           
            Spacer()
            
            HStack {
                Spacer()
                
                if let selectedImage = selectedImage {
                    ZStack(alignment: .topTrailing) {
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
                                .background(
                                    Circle()
                                        .fill(colorScheme == .dark ? Color.black : Color.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                )
                        }
                        .offset(x: 8, y: -8)
                    }
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                            Text("Select Image")
                                .font(.subheadline)
                        }
                        .foregroundColor(universalAccentColor)
                        .frame(maxWidth: 150, maxHeight: 100)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(borderColor, lineWidth: 1)
                        )
                    }
                }
                
                Spacer()
            }
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)
    }
}

// MARK: - Submit Button Component
struct SubmitButtonView: View {
    @ObservedObject var viewModel: FeedbackViewModel
    var message: String
    var onSubmit: () -> Void
    
    var body: some View {
        Button(action: onSubmit) {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                        .padding(.trailing, 8)
                }
                Text(viewModel.isSubmitting ? "Submitting..." : "Submit Feedback")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(universalAccentColor)
                    .opacity(message.isEmpty || viewModel.isSubmitting ? 0.6 : 1.0)
            )
        }
        .disabled(message.isEmpty || viewModel.isSubmitting)
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isSubmitting)
    }
}

// MARK: - Feedback Status Component
struct FeedbackStatusView: View {
    @ObservedObject var viewModel: FeedbackViewModel
    var onSuccess: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            if let successMessage = viewModel.successMessage {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                    Text(successMessage)
                        .font(.body)
                }
                .foregroundColor(successColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(successColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(successColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .onAppear {
                    // Dismiss after showing success message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onSuccess()
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 16))
                    Text(errorMessage)
                        .font(.body)
                }
                .foregroundColor(errorColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(errorColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(errorColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var successColor: Color {
        colorScheme == .dark ? Color.green.opacity(0.8) : Color.green
    }
    
    private var errorColor: Color {
        colorScheme == .dark ? Color.red.opacity(0.8) : Color.red
    }
}

// MARK: - Main Feedback View
struct FeedbackView: View {
    @StateObject private var viewModel: FeedbackViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedType: FeedbackType = .GENERAL_FEEDBACK
    @State private var message: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isTextFieldFocused: Bool = false
    
    let userId: UUID?
    let email: String?
    
    init(userId: UUID?, email: String?, apiService: IAPIService = APIService()) {
        self.userId = userId
        self.email = email
        _viewModel = StateObject(wrappedValue: FeedbackViewModel(apiService: apiService))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Feedback type selector
                    FeedbackTypeSelector(selectedType: $selectedType)
                        .padding(.top, 10)
                    
                    // Message input
                    MessageInputView(message: $message, isFocused: $isTextFieldFocused)
                    
                    // Image picker
                    ImagePickerView(selectedItem: $selectedItem, selectedImage: $selectedImage)
                        .onChange(of: selectedItem) { _, newItem in
                            loadTransferable(from: newItem)
                        }
                    
                    // Submit button
                    SubmitButtonView(
                        viewModel: viewModel,
                        message: message,
                        onSubmit: {
                            Task {
                                await viewModel.submitFeedback(
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
                        viewModel: viewModel,
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
        }
        .background(universalBackgroundColor)
        .navigationBarHidden(true)
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(universalAccentColor)
                    .font(.title3)
                    .padding(.all, 8)
                    .background(
                        Circle()
                            .fill(universalAccentColor.opacity(0.1))
                            .opacity(0)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
            
            Spacer()
            
            Text("Send Feedback")
                .font(.headline)
                .foregroundColor(universalAccentColor)
            
            Spacer()
            
            // Empty view for balance
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(
            Rectangle()
                .fill(universalBackgroundColor)
                .shadow(color: universalAccentColor.opacity(0.1), radius: 1, x: 0, y: 1)
        )
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
    FeedbackView(userId: UUID(), email: "user@example.com").environmentObject(appCache)
} 
