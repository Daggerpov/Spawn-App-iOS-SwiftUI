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
        
        // Use a local variable to get the name
        let initialName = UserAuthViewModel.shared.spawnUser?.firstName ?? ""
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
                VStack(alignment: .leading, spacing: 20) {
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
                    .foregroundColor(.blue)
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
    }
    
    private func saveProfile() {
        isSaving = true
        
        Task {
            // Check if there's a new profile picture
            let hasNewProfilePicture = selectedImage != nil
            
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
            Spacer()
            ZStack(alignment: .bottomTrailing) {
                if isImageLoading {
                    ProgressView()
                        .frame(width: 120, height: 120)
                } else if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let profilePicture = UserAuthViewModel.shared.spawnUser?.profilePicture {
                    AsyncImage(url: URL(string: profilePicture)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                            .frame(width: 120, height: 120)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }
                
                // Edit button
                Circle()
                    .fill(profilePicPlusButtonColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    )
                    .onTapGesture {
                        showImagePicker = true
                    }
            }
            Spacer()
        }
        .padding(.top, 10)
    }
}

// MARK: - Personal Info Section
struct PersonalInfoSection: View {
    @Binding var name: String
    @Binding var username: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Full Name", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            
            // Username field
            VStack(alignment: .leading, spacing: 8) {
                Text("Username")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("@")
                        .foregroundColor(.gray)
                    
                    TextField("username", text: $username)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Interests + Hobbies (Max \(maxInterests))")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            TextField("Type and press enter to add...", text: $newInterest)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .onSubmit {
                    addInterest()
                }
            
            // Existing interests as chips
            if !profileViewModel.userInterests.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
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
                .padding(.leading, 10)
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
                    .padding(8)
            }
        }
        .padding(.vertical, 5)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
    }
}

// MARK: - Social Media Section
struct SocialMediaSection: View {
    @Binding var whatsappLink: String
    @Binding var instagramLink: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .padding(.trailing, 10)
            
            TextField(placeholder, text: $text)
                .foregroundColor(universalAccentColor)
                .keyboardType(keyboardType)
            
            Spacer()
            
            Button(action: {
                // Clear the field
                text = ""
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(universalAccentColor)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
} 
