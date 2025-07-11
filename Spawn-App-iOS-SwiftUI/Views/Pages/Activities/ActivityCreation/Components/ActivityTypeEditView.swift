import SwiftUI

struct ActivityTypeEditView: View {
    let activityTypeDTO: ActivityTypeDTO
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var editedTitle: String = ""
    @State private var editedIcon: String = ""
    @State private var hasChanges: Bool = false
    @State private var navigateToFriendSelection: Bool = false
    @State private var showEmojiPicker: Bool = false
    @State private var emojiInputText: String = ""
    @FocusState private var isTitleFieldFocused: Bool
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
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(universalAccentColor)
                        .font(.title3)
                }
                
                Spacer()
                
                Text("New Activity Type")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                
                Spacer()
                
                // Empty view for balance
                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Main content
            ZStack {
                // Background - adaptive to light/dark mode
                universalBackgroundColor
                    .ignoresSafeArea()
                
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
                        showEmojiPicker = true
                    }) {
                        Text(editedIcon)
                            .font(.system(size: 40))
                    }
                    
                    // Edit button overlay - positioned at bottom right
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showEmojiPicker = true
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
                            .offset(x: 15, y: 15)
                        }
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
                    .focused($isTitleFieldFocused)
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
            
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEmojiPicker) {
            NavigationView {
                VStack {
                    TextField("", text: $editedIcon)
                        .font(.system(size: 60))
                        .multilineTextAlignment(.center)
                        .keyboardType(.default)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            // Focus the text field to show keyboard
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                }
                .navigationTitle("Choose Emoji")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showEmojiPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onAppear {
            setupInitialState()
            // Auto-focus the title field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTitleFieldFocused = true
            }
        }
        .onChange(of: editedTitle) { _ in
            updateHasChanges()
            // Apply optimistic update immediately
            optimisticallyUpdateActivityType()
        }
        .onChange(of: editedIcon) { _ in
            updateHasChanges()
            // Apply optimistic update immediately
            optimisticallyUpdateActivityType()
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
            title: editedTitle,
            icon: editedIcon,
            associatedFriends: activityTypeDTO.associatedFriends,
            orderNum: activityTypeDTO.orderNum,
            isPinned: activityTypeDTO.isPinned
        )
    }
    
    private func saveChanges() {
		let updatedActivityType = createUpdatedActivityType()
		viewModel.updateActivityType(updatedActivityType)
        Task {
            await viewModel.saveBatchChanges()
            
            // Dismiss after saving
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    private func optimisticallyUpdateActivityType() {
        let optimisticActivityType = createUpdatedActivityType()
        viewModel.optimisticallyUpdateActivityType(optimisticActivityType)
    }
}



// MARK: - Preview
@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    
    NavigationView {
        ActivityTypeEditView(activityTypeDTO: ActivityTypeDTO.createNew())
            .environmentObject(appCache)
    }
} 
