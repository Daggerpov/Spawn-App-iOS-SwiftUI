//
//  ProfileView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import PhotosUI
import SwiftUI

struct ProfileView: View {
    let user: BaseUserDTO
    @State private var username: String
    @State private var firstName: String
    @State private var lastName: String
    @State private var editingState: ProfileEditText = .edit
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var isImageLoading: Bool = false
    @State private var showNotification: Bool = false
    @State private var notificationMessage: String = ""
    @State private var newInterest: String = ""
    @State private var whatsappLink: String = ""
    @State private var instagramLink: String = ""
    @State private var showDrawer: Bool = false

    @StateObject var userAuth = UserAuthViewModel.shared
    @StateObject var profileViewModel = ProfileViewModel()

    // Check if this is the current user's profile
    private var isCurrentUserProfile: Bool {
        if MockAPIService.isMocking {
            return true
        }
        guard let currentUser = userAuth.spawnUser else { return false }
        return currentUser.id == user.id
    }

    init(user: BaseUserDTO) {
        self.user = user
        username = user.username
        firstName = user.firstName ?? ""
        lastName = user.lastName ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .center, spacing: 10) {
                        // Profile Picture
                        ProfilePictureSection(
                            user: user,
                            selectedImage: $selectedImage,
                            showImagePicker: $showImagePicker,
                            isImageLoading: $isImageLoading,
                            isEditing: editingState == .save,
                            isCurrentUserProfile: isCurrentUserProfile
                        )
                        .padding(.top, 5)
                        
                        Text(FormatterService.shared.formatName(user: user))
                            .font(.title2)
                            .bold()
                            .foregroundColor(universalAccentColor)
                        
                        Text("@\(user.username)")
                            .font(.body)
                            .foregroundColor(universalAccentColor)
                        
                        
                        // Edit/Save/Cancel buttons
                        if isCurrentUserProfile {
                            ProfileEditButtonsSection(
                                editingState: $editingState,
                                username: $username,
                                firstName: $firstName,
                                lastName: $lastName,
                                selectedImage: $selectedImage,
                                isImageLoading: $isImageLoading,
                                userAuth: userAuth,
                                showNotification: $showNotification,
                                notificationMessage: $notificationMessage,
                                profileViewModel: profileViewModel,
                                whatsappLink: $whatsappLink,
                                instagramLink: $instagramLink
                            )
                            .padding(.bottom, 10)
                        }


                        // Interests Section
                        InterestsSection(
                            isCurrentUserProfile: isCurrentUserProfile,
                            editingState: editingState,
                            profileViewModel: profileViewModel,
                            newInterest: $newInterest,
                            userId: user.id
                        )
                        .padding(.horizontal)


                        // Social Media Section
                        SocialMediaSection(
                            isCurrentUserProfile: isCurrentUserProfile,
                            editingState: editingState,
                            profileViewModel: profileViewModel,
                            whatsappLink: $whatsappLink,
                            instagramLink: $instagramLink,
                            userId: user.id
                        )
                        .padding(.horizontal)

                        // User Stats
                        UserStatsSection(profileViewModel: profileViewModel)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                    }
                    .padding(.horizontal)
                }
                .background(universalBackgroundColor)
                .navigationBarItems(
                    trailing: Button(action: {
                        withAnimation {
                            showDrawer.toggle()
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(universalAccentColor)
                            .font(.title2)
                    }
                )

                // Drawer Menu
                if showDrawer {
                    DrawerMenu(
                        isShowing: $showDrawer,
                        user: user,
                        userAuth: userAuth
                    )
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .alert(item: $userAuth.activeAlert) { alertType in
            switch alertType {
            case .deleteConfirmation:
                return Alert(
                    title: Text("Delete Account"),
                    message: Text(
                        "Are you sure you want to delete your account? This action cannot be undone."
                    ),
                    primaryButton: .destructive(Text("Delete")) {
                        Task {
                            await userAuth.deleteAccount()
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .deleteSuccess:
                return Alert(
                    title: Text("Account Deleted"),
                    message: Text(
                        "Your account has been successfully deleted."
                    ),
                    dismissButton: .default(Text("OK")) {
                        userAuth.signOut()
                    }
                )
            case .deleteError:
                return Alert(
                    title: Text("Error"),
                    message: Text(
                        "Failed to delete your account. Please try again later."
                    ),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            // Update local state from userAuth.spawnUser when view appears
            if isCurrentUserProfile, let currentUser = userAuth.spawnUser {
                username = currentUser.username
                firstName = currentUser.firstName ?? ""
                lastName = currentUser.lastName ?? ""
            }

            // Load profile data
            Task {
                await profileViewModel.loadAllProfileData(userId: user.id)

                // Initialize social media links
                if let socialMedia = profileViewModel.userSocialMedia {
                    await MainActor.run {
                        whatsappLink = socialMedia.whatsappLink ?? ""
                        instagramLink = socialMedia.instagramLink ?? ""
                    }
                }
            }
        }
        .onChange(of: userAuth.spawnUser) { newUser in
            // Update local state whenever spawnUser changes
            if isCurrentUserProfile, let currentUser = newUser {
                username = currentUser.username
                firstName = currentUser.firstName ?? ""
                lastName = currentUser.lastName ?? ""
            }
        }
        .accentColor(universalAccentColor)
        .toast(
            isShowing: $showNotification,
            message: notificationMessage,
            duration: 3.0
        )
    }
}

// MARK: - User Stats Section
struct UserStatsSection: View {
    @ObservedObject var profileViewModel: ProfileViewModel

    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 25) {
                StatItem(
                    value: profileViewModel.userStats?.peopleMet ?? 0,
                    label: "People\nmet",
                    icon: "person.2.fill"
                )

                StatItem(
                    value: profileViewModel.userStats?.spawnsMade ?? 0,
                    label: "Spawns\nmade",
                    icon: "star.fill"
                )

                StatItem(
                    value: profileViewModel.userStats?.spawnsJoined ?? 0,
                    label: "Spawns\njoined",
                    icon: "calendar.badge.plus"
                )
            }
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(universalAccentColor)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(universalAccentColor)

                Text(label)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(universalAccentColor)
            }
        }
    }
}

// MARK: - Interests Section
struct InterestsSection: View {
    let isCurrentUserProfile: Bool
    let editingState: ProfileEditText
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var newInterest: String
    let userId: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interests + Hobbies")
                .font(.headline)
                .foregroundColor(universalAccentColor)

            if profileViewModel.isLoadingInterests {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if profileViewModel.userInterests.isEmpty {
                Text("No interests added yet.")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                // Display interests as a wrapped flow
                FlowLayout(
                    mode: .scrollable,
                    items: profileViewModel.userInterests
                ) { interest in
                    InterestChip(
                        interest: interest,
                        isEditing: isCurrentUserProfile && editingState == .save
                    )
                }
            }

            // Add new interest input field
            if isCurrentUserProfile && editingState == .save {
                HStack {
                    TextField("Add interest...", text: $newInterest)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)

                    Button(action: {
                        addInterest()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(universalAccentColor)
                            .font(.title2)
                    }
                    .disabled(newInterest.isEmpty)
                }
                .padding(.top, 5)
            }
        }
    }

    private func addInterest() {
        guard !newInterest.isEmpty else { return }

        Task {
            await profileViewModel.addUserInterest(
                userId: userId,
                interest: newInterest
            )
            await MainActor.run {
                newInterest = ""
            }
        }
    }
}

struct InterestChip: View {
    let interest: String
    let isEditing: Bool

    var body: some View {
        HStack {
            Text(interest)
                .font(.subheadline)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(universalAccentColor)
                .clipShape(Capsule())

            if isEditing {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                    .offset(x: -5, y: 0)
            }
        }
    }
}

// Flow layout for displaying interests
struct FlowLayout<T: Hashable, V: View>: View {
    enum Mode {
        case stack
        case scrollable
    }

    let mode: Mode
    let items: [T]
    let viewBuilder: (T) -> V

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geometry in
                generateContent(in: geometry)
            }
        }
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                viewBuilder(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0
                        } else {
                            width -= dimension.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Social Media Section
struct SocialMediaSection: View {
    let isCurrentUserProfile: Bool
    let editingState: ProfileEditText
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var whatsappLink: String
    @Binding var instagramLink: String
    let userId: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Third party apps")
                .font(.headline)
                .foregroundColor(universalAccentColor)

            if profileViewModel.isLoadingSocialMedia {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(spacing: 12) {
                    // Instagram
                    SocialMediaItem(
                        platform: "Instagram",
                        icon: "instagram",
                        link: isCurrentUserProfile && editingState == .save
                            ? $instagramLink
                            : .constant(
                                profileViewModel.userSocialMedia?.instagramLink
                                    ?? ""
                            ),
                        isEditing: isCurrentUserProfile
                            && editingState == .save,
                        placeholder: "@username"
                    )

                    // WhatsApp
                    SocialMediaItem(
                        platform: "WhatsApp",
                        icon: "whatsapp",
                        link: isCurrentUserProfile && editingState == .save
                            ? $whatsappLink
                            : .constant(
                                profileViewModel.userSocialMedia?.whatsappLink
                                    ?? ""
                            ),
                        isEditing: isCurrentUserProfile
                            && editingState == .save,
                        placeholder: "+1 604 123 1234"
                    )

                    if isCurrentUserProfile && editingState == .save {
                        HStack {
                            Spacer()
                            Button(action: {
                                // Add functionality to add another social platform
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                        .foregroundColor(universalAccentColor)
                                    Text("Add another")
                                        .foregroundColor(universalAccentColor)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            Color.gray.opacity(0.5),
                                            lineWidth: 1
                                        )
                                        .frame(maxWidth: .infinity)
                                )
                            }
                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                }
            }
        }
    }
}

struct SocialMediaItem: View {
    let platform: String
    let icon: String
    @Binding var link: String
    let isEditing: Bool
    let placeholder: String

    var body: some View {
        HStack {
            // Platform icon (use system icon or custom asset)
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Color.gray)
                .padding(.trailing, 10)

            if isEditing {
                TextField(placeholder, text: $link)
                    .foregroundColor(universalAccentColor)
            } else {
                Text(link.isEmpty ? placeholder : link)
                    .foregroundColor(
                        link.isEmpty ? Color.gray : universalAccentColor
                    )
            }

            Spacer()

            if !isEditing {
                Button(action: {
                    // Open the social media app or profile
                    openSocialMediaLink(platform: platform, link: link)
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(universalAccentColor)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }

    private func openSocialMediaLink(platform: String, link: String) {
        // Handle different platforms
        var urlString: String?

        switch platform {
        case "Instagram":
            if link.hasPrefix("@") {
                let username = link.dropFirst()  // Remove the @ symbol
                urlString = "https://instagram.com/\(username)"
            } else {
                urlString = link.hasPrefix("http") ? link : "https://\(link)"
            }
        case "WhatsApp":
            // Format phone number for WhatsApp
            let cleanNumber = link.replacingOccurrences(
                of: "[^0-9]",
                with: "",
                options: .regularExpression
            )
            urlString = "https://wa.me/\(cleanNumber)"
        default:
            urlString = link
        }

        // Open URL if valid
        if let urlString = urlString, let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Drawer Menu
struct DrawerMenu: View {
    @Binding var isShowing: Bool
    let user: BaseUserDTO
    let userAuth: UserAuthViewModel

    var body: some View {
        ZStack(alignment: .trailing) {
            // Dim background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }

            // Menu content
            VStack(spacing: 15) {
                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding()
                    }
                }

                NavigationLink(destination: NotificationSettingsView()) {
                    DrawerMenuItem(
                        icon: "bell.fill",
                        title: "Notifications",
                        color: universalAccentColor
                    )
                }

                NavigationLink(
                    destination: FeedbackView(
                        userId: user.id,
                        email: user.email
                    )
                ) {
                    DrawerMenuItem(
                        icon: "message.fill",
                        title: "Feedback",
                        color: universalAccentColor
                    )
                }

                Button(action: {
                    if userAuth.isLoggedIn {
                        userAuth.signOut()
                    }
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    DrawerMenuItem(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "Log Out",
                        color: profilePicPlusButtonColor
                    )
                }

                Button(action: {
                    userAuth.activeAlert = .deleteConfirmation
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    DrawerMenuItem(
                        icon: "trash.fill",
                        title: "Delete Account",
                        color: .red
                    )
                }

                Spacer()
            }
            .frame(width: 250)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10, corners: [.topLeft, .bottomLeft])
        }
    }
}

struct DrawerMenuItem: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)

            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()
        }
        .padding()
        .background(color)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// Extension for custom corner rounding
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Profile Picture Section
struct ProfilePictureSection: View {
    let user: BaseUserDTO
    @Binding var selectedImage: UIImage?
    @Binding var showImagePicker: Bool
    @Binding var isImageLoading: Bool
    let isEditing: Bool
    let isCurrentUserProfile: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isImageLoading {
                ProgressView()
                    .frame(width: 150, height: 150)
            } else if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .ProfileImageModifier(imageType: .profilePage)
                    .transition(.opacity)
                    .id("selectedImage-\(UUID().uuidString)")
            } else if let profilePictureString = user.profilePicture {
                if MockAPIService.isMocking {
                    Image(profilePictureString)
                        .ProfileImageModifier(imageType: .profilePage)
                } else {
                    AsyncImage(url: URL(string: profilePictureString)) {
                        phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 150, height: 150)
                        case .success(let image):
                            image
                                .ProfileImageModifier(imageType: .profilePage)
                                .transition(.opacity.animation(.easeInOut))
                        case .failure:
                            Image(systemName: "person.crop.circle.fill")
                                .ProfileImageModifier(imageType: .profilePage)
                        @unknown default:
                            Image(systemName: "person.crop.circle.fill")
                                .ProfileImageModifier(imageType: .profilePage)
                        }
                    }
                    .id("profilePicture-\(profilePictureString)")
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .ProfileImageModifier(imageType: .profilePage)
            }

            // Only show the plus button for current user's profile when in edit mode
            if isCurrentUserProfile && isEditing {
                Circle()
                    .fill(profilePicPlusButtonColor)
                    .frame(width: 25, height: 25)
                    .overlay(
                        Image(systemName: "plus")
                            .foregroundColor(universalBackgroundColor)
                    )
                    .offset(x: -10, y: -10)
                    .onTapGesture {
                        showImagePicker = true
                    }
            }
        }
        .animation(.easeInOut, value: selectedImage != nil)
        .animation(.easeInOut, value: isImageLoading)
        .sheet(
            isPresented: $showImagePicker,
            onDismiss: {
                // Only show loading if we actually have a new image
                if selectedImage != nil {
                    DispatchQueue.main.async {
                        isImageLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isImageLoading = false
                        }
                    }
                }
            }
        ) {
            SwiftUIImagePicker(selectedImage: $selectedImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedImage) { newImage in
            if newImage != nil {
                // Force UI update when image changes
                DispatchQueue.main.async {
                    isImageLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isImageLoading = false
                    }
                }
            }
        }
        .id(
            "profilePicture-\(selectedImage != nil ? "selected" : "none")-\(isImageLoading ? "loading" : "ready")"
        )
    }
}

// MARK: - Profile Edit Buttons Section
struct ProfileEditButtonsSection: View {
    @Binding var editingState: ProfileEditText
    @Binding var username: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var selectedImage: UIImage?
    @Binding var isImageLoading: Bool
    let userAuth: UserAuthViewModel
    @Binding var showNotification: Bool
    @Binding var notificationMessage: String
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var whatsappLink: String
    @Binding var instagramLink: String

    var body: some View {
        ZStack {
            if editingState == .save {
                HStack(spacing: 20) {
                    // Cancel Button
                    Button(action: {
                        // Revert to original values from userAuth.spawnUser
                        if let currentUser = userAuth.spawnUser {
                            username = currentUser.username
                            firstName = currentUser.firstName ?? ""
                            lastName = currentUser.lastName ?? ""
                            selectedImage = nil

                            // Revert social media links
                            if let socialMedia = profileViewModel
                                .userSocialMedia
                            {
                                whatsappLink = socialMedia.whatsappLink ?? ""
                                instagramLink = socialMedia.instagramLink ?? ""
                            }
                        }
                        editingState = .edit
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(universalAccentColor)
                            .frame(maxWidth: 135)
                            .padding()
                            .background(
                                RoundedRectangle(
                                    cornerRadius: universalRectangleCornerRadius
                                )
                                .stroke(universalAccentColor, lineWidth: 1)
                            )
                    }

                    // Save Button
                    Button(action: {
                        Task {
                            await saveProfile()
                        }
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: 135)
                            .padding()
                            .background(
                                RoundedRectangle(
                                    cornerRadius: universalRectangleCornerRadius
                                )
                                .fill(profilePicPlusButtonColor)
                            )
                    }
                    .disabled(isImageLoading)
                }
            } else {
                Button(action: {
                    editingState = .save
                }) {
                    Text("Edit")
                        .font(.headline)
                        .foregroundColor(universalAccentColor)
                        .frame(maxWidth: 135)
                        .padding()
                        .background(
                            RoundedRectangle(
                                cornerRadius: universalRectangleCornerRadius
                            )
                            .stroke(universalAccentColor, lineWidth: 1)
                        )
                }
            }
        }
    }

    private func saveProfile() async {
        // Check if there's a new profile picture
        let hasNewProfilePicture = selectedImage != nil

        // Set loading state immediately if there's an image
        isImageLoading = hasNewProfilePicture

        guard let userId = userAuth.spawnUser?.id else { return }

        // Create a local copy of the selected image before starting async task
        let imageToUpload = selectedImage

        // Update profile info first
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

        // Small delay before processing image update to ensure the text updates are complete
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

        // Show notification if there's a profile picture change
        if hasNewProfilePicture {
            await MainActor.run {
                notificationMessage =
                    "Sit tight –– your profile pic will update in just a minute..."
                withAnimation {
                    showNotification = true
                }
            }
        }

        // Update profile picture if selected
        if let newImage = imageToUpload {
            await userAuth.updateProfilePicture(newImage)

            // Small delay after image upload to ensure the server has processed it
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
        }

        if let updatedUser = userAuth.spawnUser {
            username = updatedUser.username
            firstName = updatedUser.firstName ?? ""
            lastName = updatedUser.lastName ?? ""
        }

        // Refresh profile data
        await profileViewModel.loadAllProfileData(userId: userId)

        // Update local state with the latest data from the user object
        await MainActor.run {
            // Clear the selected image to force the view to refresh from the server
            selectedImage = nil
            isImageLoading = false
            editingState = .edit
        }
    }
}

@available(iOS 17, *)
#Preview {
    ProfileView(user: BaseUserDTO.danielAgapov)
}
