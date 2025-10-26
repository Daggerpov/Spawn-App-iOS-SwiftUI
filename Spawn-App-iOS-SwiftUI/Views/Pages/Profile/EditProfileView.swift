import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userAuth = UserAuthViewModel.shared
    @ObservedObject var profileViewModel: ProfileViewModel
    
    @State private var name: String
    @State private var username: String
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var isImageLoading: Bool = false
    @State private var newInterest: String = ""
    @State private var whatsappLink: String
    @State private var instagramLink: String
    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    // User ID to edit
    let userId: UUID
    
    // Maximum number of interests allowed
    private let maxInterests = 7
    
    init(userId: UUID, profileViewModel: ProfileViewModel) {
        self.userId = userId
        self.profileViewModel = profileViewModel
        
        var initialName = ""
        
        // Use a local variable to get the name
        if let spawnUser = UserAuthViewModel.shared.spawnUser {
            initialName = FormatterService.shared.formatName(user: spawnUser)
        }
        let initialUsername = UserAuthViewModel.shared.spawnUser?.username ?? ""
        
        // Initialize with raw values instead of links
        let initialWhatsapp = profileViewModel.userSocialMedia?.whatsappNumber ?? ""
        let initialInstagram = profileViewModel.userSocialMedia?.instagramUsername ?? ""
        
        _name = State(initialValue: initialName)
        _username = State(initialValue: initialUsername)
        _whatsappLink = State(initialValue: initialWhatsapp)
        _instagramLink = State(initialValue: initialInstagram)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Header with Cancel and Save buttons
                HStack {
                    // Cancel Button
                    Button("Cancel") {
                        // Restore original interests
                        profileViewModel.restoreOriginalInterests()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(figmaBittersweetOrange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(figmaBittersweetOrange, lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    // Title
                    Text("Edit Profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(universalAccentColor)
                    
                    Spacer()
                    
                    // Save Button
                    Button("Save") {
                        saveProfile()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSaving ? .gray : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSaving ? Color.gray.opacity(0.3) : figmaSoftBlue)
                    )
                    .disabled(isSaving)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(universalBackgroundColor)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Profile picture section
                        ProfileImageSection(
                            selectedImage: $selectedImage,
                            showImagePicker: $showImagePicker,
                            isImageLoading: $isImageLoading
                        )
                        
                        // Name and username fields
                        PersonalInfoSection(
                            name: $name,
                            username: $username
                        )
                        
                        // Interests section
                        InterestsSection(
                            profileViewModel: profileViewModel,
                            userId: userId,
                            newInterest: $newInterest,
                            maxInterests: maxInterests,
                            showAlert: $showAlert,
                            alertMessage: $alertMessage
                        )
                        
                        // Third party apps section
                        SocialMediaSection(
                            whatsappLink: $whatsappLink,
                            instagramLink: $instagramLink
                        )
                        
                        Spacer()
                    }
                }
            }
            .background(universalBackgroundColor)
            .navigationBarHidden(true)
            .sheet(isPresented: $showImagePicker) {
                SwiftUIImagePicker(selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Profile Update"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .accentColor(universalAccentColor)
        .onAppear {
            // Save original interests for cancel functionality
            profileViewModel.saveOriginalInterests()
            
            // Update text fields with current social media data if available
            // This handles the case where data loads after view initialization
            if let socialMedia = profileViewModel.userSocialMedia {
                whatsappLink = socialMedia.whatsappNumber ?? ""
                instagramLink = socialMedia.instagramUsername ?? ""
            }
        }
        .onChange(of: profileViewModel.userSocialMedia) { _, newSocialMedia in
            // Update text fields whenever social media data changes
            if let socialMedia = newSocialMedia {
                whatsappLink = socialMedia.whatsappNumber ?? ""
                instagramLink = socialMedia.instagramUsername ?? ""
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        Task {
            // Check if there's a new profile picture
            _ = selectedImage != nil
            
            // Update profile info first
            await userAuth.spawnEditProfile(
                username: username,
                name: name
            )
            
            // Force UI update by triggering objectWillChange
            await MainActor.run {
                userAuth.objectWillChange.send()
            }
            
            // Explicitly fetch updated user data
            await userAuth.fetchUserData()
            
            // Format social media links properly before saving
            let formattedWhatsapp = FormatterService.shared.formatWhatsAppLink(whatsappLink)
            let formattedInstagram = FormatterService.shared.formatInstagramLink(instagramLink)
            
            print("Saving whatsapp: \(formattedWhatsapp), instagram: \(formattedInstagram)")
            
            // Update social media links
            await profileViewModel.updateSocialMedia(
                userId: userId,
                whatsappLink: formattedWhatsapp.isEmpty ? nil : formattedWhatsapp,
                instagramLink: formattedInstagram.isEmpty ? nil : formattedInstagram
            )
            
            // Handle interest changes
            await saveInterestChanges()
            
            // Add an explicit delay and refresh to ensure data is properly updated
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds delay
            
            // Specifically fetch social media again to ensure it's updated
            await profileViewModel.fetchUserSocialMedia(userId: userId)
            
            // Update profile picture if selected
            if let newImage = selectedImage {
                await userAuth.updateProfilePicture(newImage)
                // Invalidate the cached profile picture since we have a new one
                ProfilePictureCache.shared.removeCachedImage(for: userId)
            }
            
            // Refresh all profile data
            await profileViewModel.loadAllProfileData(userId: userId)
            
            // Ensure the user object is fully refreshed
            if let spawnUser = userAuth.spawnUser {
                print("Updated profile: \(spawnUser.name ?? "Unknown"), @\(spawnUser.username ?? "unknown")")
                await MainActor.run {
                    userAuth.objectWillChange.send()
                }
            }
            
            await MainActor.run {
                isSaving = false
                alertMessage = "Profile updated successfully"
                showAlert = true
                
                // Dismiss after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func saveInterestChanges() async {
        let currentInterests = Set(profileViewModel.userInterests)
        let originalInterests = Set(profileViewModel.originalUserInterests)
        
        // Find interests to add (in current but not in original)
        let interestsToAdd = currentInterests.subtracting(originalInterests)
        
        // Find interests to remove (in original but not in current)
        let interestsToRemove = originalInterests.subtracting(currentInterests)
        
        // Add new interests
        for interest in interestsToAdd {
            _ = await profileViewModel.addUserInterest(userId: userId, interest: interest)
        }
        
        // Remove old interests using the edit-specific method that handles 404 as success
        for interest in interestsToRemove {
            await profileViewModel.removeUserInterestForEdit(userId: userId, interest: interest)
        }
        
        // Update the original interests to match current state after saving
        await MainActor.run {
            profileViewModel.originalUserInterests = profileViewModel.userInterests
        }
    }
}

// MARK: - Profile Image Section
struct ProfileImageSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var isImageLoading: Bool
    
    var body: some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                if isImageLoading {
                    ProgressView()
                        .frame(width: 110, height: 110)
                } else if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                } else if let profilePicture = UserAuthViewModel.shared.spawnUser?.profilePicture, let userId = UserAuthViewModel.shared.spawnUser?.id {
                    CachedProfileImageFlexible(
                        userId: userId,
                        url: URL(string: profilePicture),
                        width: 110,
                        height: 110
                    )
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                        .foregroundColor(.gray)
                }
                
                // Edit button
                Circle()
                    .fill(profilePicPlusButtonColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    )
                    .onTapGesture {
                        showImagePicker = true
                    }
            }
            Spacer()
        }
        .padding(.top, 10)
        .padding(.horizontal)
    }
}

// MARK: - Personal Info Section
struct PersonalInfoSection: View {
    @Binding var name: String
    @Binding var username: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Name field
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Full Name", text: $name)
                    .font(.subheadline)
                    .padding()
                    .foregroundColor(universalAccentColor)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: universalNewRectangleCornerRadius
                        )
                            .stroke(universalAccentColor, lineWidth: 1)
                    )
                    .placeholder(when: name.isEmpty) {
                        Text("Full Name")
                            .foregroundColor(universalAccentColor.opacity(0.7))
                            .font(.subheadline)
                            .padding(.leading)
                    }
            }
            
            // Username field
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("@")
                        .foregroundColor(.gray)
                    
                    TextField("username", text: $username)
                        .foregroundColor(universalAccentColor)
                        .font(.subheadline)
                        .placeholder(when: username.isEmpty) {
                            Text("username")
                                .foregroundColor(universalAccentColor.opacity(0.7))
                                .font(.subheadline)
                        }
                }
                .padding()
                .cornerRadius(10)
                .overlay(
                        RoundedRectangle(
                            cornerRadius: universalNewRectangleCornerRadius
                        )
                            .stroke(universalAccentColor, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Interests Section
struct InterestsSection: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    let userId: UUID
    @Binding var newInterest: String
    let maxInterests: Int
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interests + Hobbies (Max \(maxInterests))")
                .font(.custom("Onest", size: 16).weight(.medium))
                .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
            
            // Text field with placeholder overlay
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.86, green: 0.84, blue: 0.84))
                    .frame(height: 48)
                
                // Placeholder text
                if newInterest.isEmpty {
                    Text("Type and press enter to add...")
                        .font(.custom("Onest", size: 16))
                        .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
                        .padding(.leading, 16)
                }
                
                // Text field
                TextField("", text: $newInterest)
                    .font(.custom("Onest", size: 16))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    .padding(.horizontal, 16)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        addInterest()
                    }
                    .frame(height: 48)
            }
            
            // Existing interests as chips
            if !profileViewModel.userInterests.isEmpty {
                // Flexible layout for interests that wraps to new lines
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(Array(profileViewModel.userInterests.enumerated()), id: \.offset) { index, interest in
                        InterestChipView(interest: interest) {
                            removeInterest(interest)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: profileViewModel.userInterests)
            }
        }
        .padding(.horizontal)
    }
    
    private func addInterest() {
        guard !newInterest.isEmpty else { return }
        guard profileViewModel.userInterests.count < maxInterests else {
            alertMessage = "You can have a maximum of \(maxInterests) interests"
            showAlert = true
            return
        }
        
        let interest = newInterest.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't add duplicates
        if !profileViewModel.userInterests.contains(interest) {
            // Only update local state - don't call API until save
            profileViewModel.userInterests.append(interest)
            profileViewModel.objectWillChange.send()
            newInterest = ""
            isTextFieldFocused = false // Dismiss keyboard
        } else {
            newInterest = ""
            isTextFieldFocused = false // Dismiss keyboard
        }
    }
    
    private func removeInterest(_ interest: String) {
        // Only update local state - don't call API until save
        profileViewModel.userInterests.removeAll { $0 == interest }
        profileViewModel.objectWillChange.send()
    }
}

// MARK: - Interest Chip View
struct InterestChipView: View {
    let interest: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(interest)
                .font(.custom("Onest", size: 14).weight(.medium))
                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(red: 0.88, green: 0.36, blue: 0.45))
            }
        }
        .padding(12)
        .background(Color(red: 0.86, green: 0.84, blue: 0.84))
        .cornerRadius(100)
    }
}

// MARK: - Social Media Section
struct SocialMediaSection: View {
    @Binding var whatsappLink: String
    @Binding var instagramLink: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Media")
                .font(.headline)
                .foregroundColor(universalAccentColor)
                .padding(.bottom, 4)
            
            // Instagram
            SocialMediaField(
                icon: "instagram",
                placeholder: "username (without @)",
                text: $instagramLink
            )
            
            // WhatsApp
            SocialMediaField(
                icon: "whatsapp",
                placeholder: "+1 234 567 8901",
                text: $whatsappLink,
                keyboardType: .phonePad
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Social Media Field
struct SocialMediaField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Add descriptive label based on platform
            Text(icon == "instagram" ? "Instagram Username" : "WhatsApp Number")
                .font(.subheadline)
                .foregroundColor(.gray)
                
            HStack {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .padding(.trailing, 8)
                
                // Add @ prefix for Instagram
                if icon == "instagram" && !text.hasPrefix("@") && !text.isEmpty {
                    Text("@")
                        .foregroundColor(.gray)
                }
                
                TextField(placeholder, text: $text)
                    .font(.subheadline)
                    .foregroundColor(universalAccentColor)
                    .keyboardType(keyboardType)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(universalAccentColor.opacity(0.7))
                            .font(.subheadline)
                    }
                
                Spacer()
            }
            .padding()
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(
                    cornerRadius: universalNewRectangleCornerRadius
                )
                    // TODO DANIEL A: adjust this color to be the gradient of the logo, like in Figma
                    .stroke(icon == "instagram" ? Color(red: 1, green: 0.83, blue: 0.33) : Color(red: 0.37, green: 0.98, blue: 0.47), lineWidth: 1)
            )
            
            // Add helpful hint text
            Text(icon == "instagram" ? "Enter your Instagram handle (with or without @)" : "Only for your friends to see")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.leading, 2)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var profileViewModel = ProfileViewModel(
		userId: BaseUserDTO.danielAgapov.id,
        apiService: MockAPIService(userId: BaseUserDTO.danielAgapov.id)
    )

    EditProfileView(
        userId: BaseUserDTO.danielAgapov.id,
        profileViewModel: profileViewModel
    )
} 
