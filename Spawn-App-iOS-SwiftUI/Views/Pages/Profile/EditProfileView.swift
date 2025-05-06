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
        let initialWhatsapp = profileViewModel.userSocialMedia?.whatsappLink ?? ""
        let initialInstagram = profileViewModel.userSocialMedia?.instagramLink ?? ""
        
        _name = State(initialValue: initialName)
        _username = State(initialValue: initialUsername)
        _whatsappLink = State(initialValue: initialWhatsapp)
        _instagramLink = State(initialValue: initialInstagram)
    }
    
    var body: some View {
        NavigationView {
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
            .background(universalBackgroundColor)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .foregroundColor(universalAccentColor)
                    .disabled(isSaving)
                    .opacity(isSaving ? 0.5 : 1.0)
                }
            }
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
    }
    
    private func saveProfile() {
        isSaving = true
        
        Task {
            // Check if there's a new profile picture
            _ = selectedImage != nil
            
            // Update profile info first
            let firstName = name.split(separator: " ").first.map(String.init) ?? name
            let lastName = name.contains(" ") ? name.split(separator: " ").dropFirst().joined(separator: " ") : ""
            
            await userAuth.spawnEditProfile(
                username: username,
                firstName: firstName,
                lastName: lastName
            )
            
            // Update social media links
            await profileViewModel.updateSocialMedia(
                userId: userId,
                whatsappLink: whatsappLink.isEmpty ? nil : whatsappLink,
                instagramLink: instagramLink.isEmpty ? nil : instagramLink
            )
            
            // Update profile picture if selected
            if let newImage = selectedImage {
                await userAuth.updateProfilePicture(newImage)
            }
            
            // Refresh profile data
            await profileViewModel.loadAllProfileData(userId: userId)
            
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
                } else if let profilePicture = UserAuthViewModel.shared.spawnUser?.profilePicture {
                    AsyncImage(url: URL(string: profilePicture)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                            .frame(width: 110, height: 110)
                    }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Interests + Hobbies (Max \(maxInterests))")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField("Type and press enter to add...", text: $newInterest)
                .font(.subheadline)
                .padding()
                .foregroundColor(universalAccentColor)
                .cornerRadius(10)
                .onSubmit {
                    addInterest()
                }
                .overlay(
                    RoundedRectangle(
                        cornerRadius: universalNewRectangleCornerRadius
                    )
                        .stroke(universalAccentColor, lineWidth: 1)
                )
                .placeholder(when: newInterest.isEmpty) {
                    Text("Type and press enter to add...")
                        .foregroundColor(universalAccentColor.opacity(0.7))
                        .font(.subheadline)
                        .padding(.leading)
                }
            
            
            // Existing interests as chips
            if !profileViewModel.userInterests.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                    ForEach(profileViewModel.userInterests, id: \.self) { interest in
                        InterestChipView(interest: interest) {
                            removeInterest(interest)
                        }
                    }
                }
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
            Task {
                await profileViewModel.addUserInterest(userId: userId, interest: interest)
                await MainActor.run {
                    newInterest = ""
                }
            }
        } else {
            newInterest = ""
        }
    }
    
    private func removeInterest(_ interest: String) {
        Task {
            await profileViewModel.removeUserInterest(userId: userId, interest: interest)
        }
    }
}

// MARK: - Interest Chip View
struct InterestChipView: View {
    let interest: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(interest)
                .font(.caption)
                .padding(.leading, 8)
                .foregroundColor(universalAccentColor)
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(6)
            }
        }
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(16)
    }
}

// MARK: - Social Media Section
struct SocialMediaSection: View {
    @Binding var whatsappLink: String
    @Binding var instagramLink: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Third party apps")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Instagram
            SocialMediaField(
                icon: "instagram",
                placeholder: "@instagram",
                text: $instagramLink
            )
            
            // WhatsApp
            SocialMediaField(
                icon: "whatsapp",
                placeholder: "+1 604 123 1234",
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
        HStack {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(.trailing, 8)
            
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
    }
}

// Extension to support placeholders with custom styling
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 
