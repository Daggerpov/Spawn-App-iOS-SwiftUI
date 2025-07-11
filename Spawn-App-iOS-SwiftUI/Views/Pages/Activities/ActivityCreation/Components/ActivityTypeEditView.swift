import SwiftUI

struct ActivityTypeEditView: View {
    let activityTypeDTO: ActivityTypeDTO
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var editedTitle: String = ""
    @State private var editedIcon: String = ""
    @State private var hasChanges: Bool = false
    @State private var isEmojiPickerPresented: Bool = false
    
    @StateObject private var viewModel: ActivityTypeViewModel
    
    init(activityTypeDTO: ActivityTypeDTO) {
        self.activityTypeDTO = activityTypeDTO
        
        // Initialize the view model with userId
        let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        self._viewModel = StateObject(wrappedValue: ActivityTypeViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            // Background
            universalBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                Spacer()
                
                // Main content
                mainContentSection
                
                Spacer()
                
                // Action buttons
                actionButtonsSection
                
                // Bottom safe area padding
                Color.clear.frame(height: 50)
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
        .sheet(isPresented: $isEmojiPickerPresented) {
            EmojiPickerView(selectedEmoji: $editedIcon)
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 32) {
            // Back button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(universalAccentColor)
            }
            
            // Title
            Text("Edit Activity Type")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(universalAccentColor)
                .frame(maxWidth: .infinity)
            
            // Placeholder for balance
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - Main Content Section
    private var mainContentSection: some View {
        VStack(spacing: 40) {
            // Activity Type Display Circle
            ZStack {
                // Main circular background
                Circle()
                    .fill(Color(red: 0.24, green: 0.23, blue: 0.23))
                    .frame(width: 180, height: 180)
                
                VStack(spacing: 20) {
                    // Icon with emoji picker button
                    ZStack {
                        // Icon background
                        Circle()
                            .fill(Color(red: 0.86, green: 0.84, blue: 0.84))
                            .frame(width: 80, height: 80)
                        
                        // Icon text
                        Text(editedIcon)
                            .font(.system(size: 32))
                        
                        // Edit icon button overlay
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    isEmojiPickerPresented = true
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 0.52, green: 0.49, blue: 0.49))
                                            .frame(width: 28, height: 28)
                                        
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    }
                                }
                                .offset(x: 8, y: -8)
                            }
                            Spacer()
                        }
                    }
                    
                    // Editable title field
                    TextField("Activity Type Name", text: $editedTitle)
                        .font(.onestMedium(size: 24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(maxWidth: 200)
                }
            }
            .frame(width: 200, height: 200)
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Save button
            Button(action: {
                saveChanges()
            }) {
                Text("Save")
                    .font(.onestSemiBold(size: 20))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(hasChanges ? figmaBlue : universalPassiveColor)
                    .cornerRadius(16)
            }
            .disabled(!hasChanges || viewModel.isLoading)
            .animation(.easeInOut(duration: 0.2), value: hasChanges)
            
            // Cancel button
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.onestSemiBold(size: 20))
                    .foregroundColor(figmaBlack300)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(figmaBlack300, lineWidth: 1)
                    )
            }
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, 40)
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
    
    private func saveChanges() {
        // Validate input
        guard !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // Create updated activity type
        let updatedActivityType = ActivityTypeDTO(
            id: activityTypeDTO.id,
            title: editedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: editedIcon,
            associatedFriends: activityTypeDTO.associatedFriends,
            orderNum: activityTypeDTO.orderNum,
            isPinned: activityTypeDTO.isPinned
        )
        
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

// MARK: - Simple Emoji Picker View
struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss
    
    private let emojis = ["🍽️", "🏃", "💼", "🛋️", "⭐️", "🎯", "🎨", "🎵", "📚", "🏀", "⚽️", "🎮", "🎪", "🎭", "🎬", "📱", "💻", "☕️", "🍕", "🍔", "🎂", "🍿", "🏊", "🚴", "🧘", "🎳", "🎪", "🎨", "🎵", "📖", "🎲", "🎯", "🎪", "🎭"]
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Select an Icon")
                    .font(.onestSemiBold(size: 24))
                    .foregroundColor(universalAccentColor)
                    .padding(.top, 20)
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 20) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button(action: {
                                selectedEmoji = emoji
                                dismiss()
                            }) {
                                Text(emoji)
                                    .font(.system(size: 40))
                                    .frame(width: 60, height: 60)
                                    .background(
                                        Circle()
                                            .fill(selectedEmoji == emoji ? figmaBlue.opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedEmoji == emoji ? figmaBlue : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .background(universalBackgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(figmaBlue)
                }
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    ActivityTypeEditView(activityTypeDTO: ActivityTypeDTO.mockChillActivityType)
} 