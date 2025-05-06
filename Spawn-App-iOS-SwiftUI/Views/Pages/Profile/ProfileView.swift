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
    @State private var currentMonth = Calendar.current.component(.month, from: Date())
    @State private var currentYear = Calendar.current.component(.year, from: Date())

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
                    VStack(alignment: .center, spacing: 15) {
                        // Profile Picture
                        profilePictureSection
                        .padding(.top, 20)
                        
                        // Name and Username
                        Text(FormatterService.shared.formatName(user: user))
                            .font(.title2)
                            .bold()
                            .foregroundColor(universalAccentColor)
                        
                        Text("@\(user.username)")
                            .font(.body)
                            .foregroundColor(Color.gray)
                            .padding(.bottom, 10)
                        
                        // Profile Action Buttons
                        profileActionButtons
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        
                        // Edit Save Cancel buttons (only when editing)
                        if isCurrentUserProfile && editingState == .save {
                            profileEditButtons
                            .padding(.bottom, 10)
                        }
                        
                        // Interests Section with Social Media Icons
                        interestsSection
                        .padding(.bottom, 20)
                        
                        // User Stats
                        userStatsSection
                        .padding(.bottom, 20)
                        
                        // Weekly Calendar View
                        weeklyCalendarView
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal)
                }
                .background(universalBackgroundColor)
                .navigationBarItems(
                    trailing: menuButton
                )

                // Drawer Menu
                if showDrawer {
                    drawerMenu
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
    
    private func addInterest() {
        guard !newInterest.isEmpty else { return }

        Task {
            await profileViewModel.addUserInterest(
                userId: user.id,
                interest: newInterest
            )
            await MainActor.run {
                newInterest = ""
            }
        }
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
    
    private func shareProfile() {
        // Create a URL to share (could be a deep link to the user's profile)
        let profileURL = "https://spawnapp.com/profile/\(user.id)"
        let shareText = "Check out \(FormatterService.shared.formatName(user: user))'s profile on Spawn!"
        
        let activityItems: [Any] = [shareText, profileURL]
        let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Present the activity controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true, completion: nil)
        }
    }
    
    private func removeInterest(_ interest: String) {
        Task {
            await profileViewModel.removeUserInterest(
                userId: user.id,
                interest: interest
            )
        }
    }
}

// MARK: - Profile Picture Section
extension ProfileView {
    private var profilePictureSection: some View {
        ZStack(alignment: .bottomTrailing) {
            if isImageLoading {
                ProgressView()
                    .frame(width: 150, height: 150)
            } else if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .transition(.opacity)
                    .id("selectedImage-\(UUID().uuidString)")
            } else if let profilePictureString = user.profilePicture {
                if MockAPIService.isMocking {
                    Image(profilePictureString)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                } else {
                    AsyncImage(url: URL(string: profilePictureString)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 150, height: 150)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                                .transition(.opacity.animation(.easeInOut))
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(Color.gray.opacity(0.5))
                        @unknown default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .foregroundColor(Color.gray.opacity(0.5))
                        }
                    }
                    .id("profilePicture-\(profilePictureString)")
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .foregroundColor(Color.gray.opacity(0.5))
            }

            // Only show the plus button for current user's profile when in edit mode
            if isCurrentUserProfile && editingState == .save {
                Circle()
                    .fill(profilePicPlusButtonColor)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
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
    }
}

// MARK: - Profile Action Buttons
extension ProfileView {
    private var profileActionButtons: some View {
        HStack(spacing: 15) {
            if isCurrentUserProfile {
                NavigationLink(destination: EditProfileView(userId: user.id, profileViewModel: profileViewModel)) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Profile")
                    }
                    .font(.subheadline)
                    .foregroundColor(universalAccentColor)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(universalAccentColor, lineWidth: 1)
                )
            }
            
            Button(action: {
                shareProfile()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Profile")
                }
                .font(.subheadline)
                .foregroundColor(universalAccentColor)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(universalAccentColor, lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Profile Edit Buttons
extension ProfileView {
    private var profileEditButtons: some View {
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

// MARK: - Interests Section
extension ProfileView {
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            interestsSectionHeader
            
            // Interests content
            if profileViewModel.isLoadingInterests {
                interestsLoadingView
            } else {
                interestsContentView
            }
        }
    }
    
    private var interestsSectionHeader: some View {
        HStack {
            Text("Interests + Hobbies")
                .font(.headline)
                .foregroundColor(universalAccentColor)
            
            Spacer()
            
            // Social media icons
            if !profileViewModel.isLoadingSocialMedia {
                socialMediaIcons
            }
        }
        .padding(.horizontal)
    }
    
    private var socialMediaIcons: some View {
        HStack(spacing: 10) {
            if !whatsappLink.isEmpty || 
               (profileViewModel.userSocialMedia?.whatsappLink ?? "").isEmpty == false {
                Image("whatsapp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .onTapGesture {
                        openSocialMediaLink(platform: "WhatsApp", 
                                           link: whatsappLink.isEmpty ? 
                                           (profileViewModel.userSocialMedia?.whatsappLink ?? "") : 
                                           whatsappLink)
                    }
            }
            
            if !instagramLink.isEmpty || 
               (profileViewModel.userSocialMedia?.instagramLink ?? "").isEmpty == false {
                Image("instagram")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .onTapGesture {
                        openSocialMediaLink(platform: "Instagram", 
                                           link: instagramLink.isEmpty ? 
                                           (profileViewModel.userSocialMedia?.instagramLink ?? "") : 
                                           instagramLink)
                    }
            }
        }
    }
    
    private var interestsLoadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
    }
    
    private var interestsContentView: some View {
        ZStack(alignment: .topLeading) {
            // Background for interests section
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.red.opacity(0.7), lineWidth: 1)
                .background(Color.white.opacity(0.5).cornerRadius(15))
            
            if profileViewModel.userInterests.isEmpty {
                emptyInterestsView
            } else {
                // Interests as chips with proper layout
                VStack(alignment: .leading) {
                    interestsFlowView
                }
                .padding()
            }
        }
        .frame(height: profileViewModel.userInterests.isEmpty ? 100 : CGFloat(min(4, (profileViewModel.userInterests.count + 1) / 2) * 40 + 20))
        .padding(.horizontal)
        .padding(.top, 5)
    }
    
    private var emptyInterestsView: some View {
        Text("No interests added yet.")
            .foregroundColor(.gray)
            .italic()
            .padding()
    }
    
    private var interestsFlowView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(profileViewModel.userInterests, id: \.self) { interest in
                interestChip(interest: interest)
            }
        }
    }
    
    private func interestChip(interest: String) -> some View {
        HStack {
            Text(interest)
                .font(.subheadline)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(universalAccentColor)
                .clipShape(Capsule())

            if isCurrentUserProfile && editingState == .save {
                Button(action: {
                    removeInterest(interest)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                        .offset(x: -5, y: 0)
                }
            }
        }
    }
}

// MARK: - User Stats Section
extension ProfileView {
    private var userStatsSection: some View {
        HStack(spacing: 40) {
            VStack(spacing: 5) {
                Image(systemName: "link")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                
                Text("\(profileViewModel.userStats?.peopleMet ?? 0)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(universalAccentColor)
                
                Text("People\nmet")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 5) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                
                Text("\(profileViewModel.userStats?.spawnsMade ?? 0)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(universalAccentColor)
                
                Text("Spawns\nmade")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 5) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                
                Text("\(profileViewModel.userStats?.spawnsJoined ?? 0)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(universalAccentColor)
                
                Text("Spawns\njoined")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Weekly Calendar
extension ProfileView {
    private var weeklyCalendarView: some View {
        VStack(spacing: 10) {
            // Month navigation and title
            HStack {
                Button(action: {
                    navigateToPreviousMonth()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(universalAccentColor)
                        .font(.title3)
                }
                
                Spacer()
                
                Text(monthYearString())
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                
                Spacer()
                
                Button(action: {
                    navigateToNextMonth()
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(universalAccentColor)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 20)
            
            // Days of week header
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
            }
            
            if profileViewModel.isLoadingCalendar {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                // Calendar grid
                VStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { row in
                        HStack(spacing: 8) {
                            ForEach(0..<7, id: \.self) { col in
                                if let activity = profileViewModel.calendarActivities[row][col] {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(activityColor(for: activity.activityType))
                                        .frame(height: 40)
                                        .overlay(
                                            activityIcon(for: activity.activityType)
                                                .foregroundColor(.white)
                                        )
                                        .onTapGesture {
                                            // Handle activity tap
                                        }
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 40)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchCalendarData()
        }
    }
    
    private var weekDays: [String] {
        ["S", "M", "T", "W", "T", "F", "S"]
    }
    
    private func navigateToPreviousMonth() {
        if currentMonth == 1 {
            currentMonth = 12
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
        fetchCalendarData()
    }
    
    private func navigateToNextMonth() {
        if currentMonth == 12 {
            currentMonth = 1
            currentYear += 1
        } else {
            currentMonth += 1
        }
        fetchCalendarData()
    }
    
    private func fetchCalendarData() {
        Task {
            await profileViewModel.fetchCalendarActivities(
                month: currentMonth,
                year: currentYear
            )
        }
    }
    
    private func monthYearString() -> String {
        let dateComponents = DateComponents(
            year: currentYear,
            month: currentMonth
        )
        if let date = Calendar.current.date(from: dateComponents) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return "\(currentMonth)/\(currentYear)"
    }
    
    private func activityColor(for activityType: String) -> Color {
        switch activityType {
        case "music": return .pink
        case "sports": return .blue
        case "food": return .green
        case "travel": return .orange
        case "gaming": return .purple
        case "outdoors": return .red
        default: return .gray
        }
    }
    
    private func activityIcon(for activityType: String) -> some View {
        let iconName: String
        switch activityType {
        case "music": iconName = "music.note"
        case "sports": iconName = "figure.walk"
        case "food": iconName = "fork.knife"
        case "travel": iconName = "airplane"
        case "gaming": iconName = "gamecontroller"
        case "outdoors": iconName = "bicycle"
        default: iconName = "star.fill"
        }
        return Image(systemName: iconName)
    }
}

// MARK: - Menu Button and Drawer
extension ProfileView {
    private var menuButton: some View {
        Button(action: {
            withAnimation {
                showDrawer.toggle()
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(universalAccentColor)
                    .font(.title3)
                    
                // User avatar in menu button
                if let profilePictureString = userAuth.spawnUser?.profilePicture, 
                   !profilePictureString.isEmpty {
                    AsyncImage(url: URL(string: profilePictureString)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        default:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Text(String(userAuth.spawnUser?.username.prefix(1) ?? "U"))
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text(String(userAuth.spawnUser?.username.prefix(1) ?? "U"))
                                .foregroundColor(.gray)
                        )
                }
            }
        }
    }
    
    private var drawerMenu: some View {
        ZStack(alignment: .trailing) {
            // Dim background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showDrawer = false
                    }
                }

            // Menu content
            VStack(spacing: 15) {
                Button(action: {
                    withAnimation {
                        showDrawer = false
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
                    drawerMenuItem(icon: "bell.fill", title: "Notifications", color: universalAccentColor)
                }

                NavigationLink(
                    destination: FeedbackView(
                        userId: user.id,
                        email: user.email
                    )
                ) {
                    drawerMenuItem(icon: "message.fill", title: "Feedback", color: universalAccentColor)
                }

                Button(action: {
                    if userAuth.isLoggedIn {
                        userAuth.signOut()
                    }
                    withAnimation {
                        showDrawer = false
                    }
                }) {
                    drawerMenuItem(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "Log Out",
                        color: profilePicPlusButtonColor
                    )
                }

                Button(action: {
                    userAuth.activeAlert = .deleteConfirmation
                    withAnimation {
                        showDrawer = false
                    }
                }) {
                    drawerMenuItem(
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
    
    private func drawerMenuItem(icon: String, title: String, color: Color) -> some View {
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

@available(iOS 17, *)
#Preview {
    ProfileView(user: BaseUserDTO.danielAgapov)
}
