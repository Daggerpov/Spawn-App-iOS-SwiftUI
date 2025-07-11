import SwiftUI

struct ActivityTypeEditView: View {
    let activityTypeDTO: ActivityTypeDTO
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var editedTitle: String = ""
    @State private var editedIcon: String = ""
    @State private var hasChanges: Bool = false
    @State private var isEmojiPickerPresented: Bool = false
    @State private var navigateToFriendSelection: Bool = false
    @State private var emojiInputText: String = ""
    @FocusState private var isEmojiTextFieldFocused: Bool
    
    @StateObject private var viewModel: ActivityTypeViewModel
    
    // Track if this is a new activity type (no associated friends yet)
    private var isNewActivityType: Bool {
        activityTypeDTO.associatedFriends.isEmpty && activityTypeDTO.title == "New Activity"
    }
    
    init(activityTypeDTO: ActivityTypeDTO) {
        self.activityTypeDTO = activityTypeDTO
        
        // Initialize the view model with userId
        let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        self._viewModel = StateObject(wrappedValue: ActivityTypeViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - adaptive to light/dark mode
                universalBackgroundColor
                    .ignoresSafeArea()
            
            // Header
            VStack {
                HStack(spacing: 32) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(universalAccentColor)
                            .font(.title3)
                    }
                    
                    Text("Create Type - Name")
                        .font(.onestSemiBold(size: 20))
                        .foregroundColor(universalAccentColor)
                        .frame(maxWidth: .infinity)
                    
                    // Empty view for balance
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                Spacer()
            }
            .offset(x: 0, y: -380)
            
            // Main circular content
            VStack(spacing: 30) {
                // Icon picker area
                ZStack {
                    // Main circular background
                    Circle()
                        .fill(Color(red: 0.86, green: 0.84, blue: 0.84))
                        .frame(width: 128, height: 128)
                    
                    // Icon display - make it clickable
                    Button(action: {
                        // Clear the input text and focus to trigger emoji keyboard
                        emojiInputText = ""
                        isEmojiTextFieldFocused = true
                    }) {
                        Text(editedIcon)
                            .font(.system(size: 40))
                    }
                    
                    // Edit button overlay
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                // Clear the input text and focus to trigger emoji keyboard
                                emojiInputText = ""
                                isEmojiTextFieldFocused = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.52, green: 0.49, blue: 0.49))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: 20, y: -20)
                        }
                        Spacer()
                    }
                }
                .frame(width: 128, height: 128)
                
                // Title text field
                TextField("New Activity", text: $editedTitle)
                    .font(.onestMedium(size: 32))
                    .foregroundColor(universalAccentColor)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(maxWidth: 250)
            }
            .padding(40)
            .frame(width: 290, height: 290)
            .background(colorScheme == .dark ? Color(red: 0.24, green: 0.23, blue: 0.23) : Color(red: 0.95, green: 0.93, blue: 0.93))
            .cornerRadius(30)
            .offset(x: 0, y: -150)
            
            // Save/Next button
            Button(action: {
                if isNewActivityType {
                    // For new activity types, navigate to friend selection
                    navigateToNextStep()
                } else {
                    // For existing activity types, save changes
                    saveChanges()
                }
            }) {
                Text(isNewActivityType ? "Next" : "Save")
                    .font(.onestSemiBold(size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(figmaBlue)
                    .cornerRadius(16)
            }
            .frame(width: 290, height: 56)
            .disabled((!hasChanges && !isNewActivityType) || viewModel.isLoading)
            .offset(x: 0, y: 40)
            
            // Cancel button
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.onestSemiBold(size: 20))
                    .foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.80))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.clear)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0.82, green: 0.80, blue: 0.80), lineWidth: 0.5)
                    )
            }
            .frame(width: 290, height: 56)
            .disabled(viewModel.isLoading)
            .offset(x: 0, y: 110)
            
            // Hidden text field for emoji input
            TextField("", text: $emojiInputText)
                .opacity(0)
                .frame(width: 0, height: 0)
                .focused($isEmojiTextFieldFocused)
                .onChange(of: emojiInputText) { newValue in
                    // Extract the last character if it's an emoji
                    if let lastChar = newValue.last, lastChar.isEmoji {
                        editedIcon = String(lastChar)
                        isEmojiTextFieldFocused = false
                    }
                }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupInitialState()
        }
        .onChange(of: editedTitle) { _ in
            updateHasChanges()
        }
        .onChange(of: editedIcon) { _ in
            updateHasChanges()
        }
        .navigationDestination(isPresented: $navigateToFriendSelection) {
            ActivityTypeFriendSelectionView(
                activityTypeDTO: createUpdatedActivityType(),
                onComplete: { finalActivityType in
                    // Save the activity type with selected friends
                    Task {
                        await viewModel.createActivityType(finalActivityType)
                        await viewModel.saveBatchChanges()
                        
                        // Dismiss both views
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
            )
            .environmentObject(AppCache.shared)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .overlay(
            // Loading overlay
            Group {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        ProgressView("Saving...")
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(universalBackgroundColor)
                            )
                    }
                }
            }
        )
        }
    }

    // MARK: - Private Methods
    private func setupInitialState() {
        editedTitle = activityTypeDTO.title
        editedIcon = activityTypeDTO.icon
        hasChanges = false
    }
    
    private func updateHasChanges() {
        hasChanges = (editedTitle != activityTypeDTO.title) || (editedIcon != activityTypeDTO.icon)
    }
    
    private func navigateToNextStep() {
        // Validate input before proceeding
        guard !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        navigateToFriendSelection = true
    }
    
    private func createUpdatedActivityType() -> ActivityTypeDTO {
        return ActivityTypeDTO(
            id: activityTypeDTO.id,
            title: editedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: editedIcon,
            associatedFriends: activityTypeDTO.associatedFriends,
            orderNum: activityTypeDTO.orderNum,
            isPinned: activityTypeDTO.isPinned
        )
    }
    
    private func saveChanges() {
        // Validate input
        guard !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Create updated activity type
        let updatedActivityType = createUpdatedActivityType()
        
        // Update through view model
        Task {
            await viewModel.updateActivityType(updatedActivityType)
            
            // Save changes to backend
            await viewModel.saveBatchChanges()
            
            // Dismiss on success
            if viewModel.errorMessage == nil {
                await MainActor.run {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Character extension for emoji detection
extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji
    }
}

// MARK: - Preview
@available(iOS 17, *)
#Preview {
    ActivityTypeEditView(activityTypeDTO: ActivityTypeDTO.mockChillActivityType)
} 