//
//  ProfileView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import PhotosUI
import SwiftUI

struct ProfileView: View {
    let user: Nameable
    @State private var username: String
    @State private var name: String
    @State private var editingState: ProfileEditText = .edit
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var isImageLoading: Bool = false
    @State private var showNotification: Bool = false
    @State private var notificationMessage: String = ""
    @State private var newInterest: String = ""
    @State private var whatsappLink: String = ""
    @State private var instagramLink: String = ""
    @State private var currentMonth = Calendar.current.component(
        .month,
        from: Date()
    )
    @State private var currentYear = Calendar.current.component(
        .year,
        from: Date()
    )
    @State private var refreshFlag = false
    @State private var showCalendarPopup: Bool = false
    @State private var showEventDetails: Bool = false
    @State private var showTagDialog: Bool = false
    @State private var showReportDialog: Bool = false
    @State private var showBlockDialog: Bool = false
    @State private var reportReason: String = ""
    @State private var blockReason: String = ""
    @State private var showRemoveFriendConfirmation: Bool = false
    @State private var showProfileMenu: Bool = false

    @StateObject var userAuth = UserAuthViewModel.shared
    @StateObject var profileViewModel = ProfileViewModel()
    
    // Add environment object for navigation
    @Environment(\.presentationMode) var presentationMode
    
    // For the back button
    @State private var showBackButton: Bool = false

    // Check if this is the current user's profile
    private var isCurrentUserProfile: Bool {
        if MockAPIService.isMocking {
            return true
        }
        guard let currentUser = userAuth.spawnUser else { return false }
        return currentUser.id == user.id
    }

    init(user: Nameable) {
        self.user = user
        self._profileViewModel = StateObject(wrappedValue: ProfileViewModel(userId: user.id))
        self.username = user.username
        self.name = user.name ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .center, spacing: 10) {
                        // Profile Header (Profile Picture + Name)
                        ProfileHeaderView(
                            user: user,
                            selectedImage: $selectedImage,
                            showImagePicker: $showImagePicker,
                            isImageLoading: $isImageLoading,
                            refreshFlag: $refreshFlag,
                            editingState: $editingState
                        )

                        // Friendship badge (for other users' profiles)
                        if !isCurrentUserProfile && profileViewModel.friendshipStatus == .friends {
                            Text("Friends")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(hex: "#4CAF50")) // Green color as in Figma
                                .cornerRadius(12)
                                .padding(.bottom, 10)
                        }

                        // Profile Action Buttons
                        if isCurrentUserProfile {
                            // Original action buttons for current user
                            ProfileActionButtonsView(
                                user: user,
                                shareProfile: shareProfile
                            )
                            .padding(.horizontal, 25)
                            .padding(.bottom, 15)
                        } else {
                            // Friend action buttons for other users (based on friendship status)
                            friendActionButtons
                                .padding(.horizontal, 25)
                                .padding(.bottom, 15)
                        }

                        // Edit Save Cancel buttons (only when editing)
                        if isCurrentUserProfile && editingState == .save {
                            ProfileEditButtonsView(
                                user: user,
                                profileViewModel: profileViewModel,
                                editingState: $editingState,
                                username: $username,
                                name: $name,
                                selectedImage: $selectedImage,
                                whatsappLink: $whatsappLink,
                                instagramLink: $instagramLink,
                                isImageLoading: $isImageLoading,
                                saveProfile: saveProfile
                            )
                            .padding(.bottom, 5)
                        }

                        // Interests Section with Social Media Icons
                        ProfileInterestsView(
                            user: user,
                            profileViewModel: profileViewModel,
                            editingState: $editingState,
                            newInterest: $newInterest,
                            openSocialMediaLink: openSocialMediaLink,
                            removeInterest: removeInterest
                        )
                        .padding(.bottom, 15)

                        // User Stats (only for current user or friends)
                        if isCurrentUserProfile || profileViewModel.friendshipStatus == .friends {
                            ProfileStatsView(
                                profileViewModel: profileViewModel
                            )
                            .padding(.bottom, 15)
                        }

                        // Weekly Calendar View (only for current user)
                        if isCurrentUserProfile {
                            ProfileCalendarView(
                                profileViewModel: profileViewModel,
                                showCalendarPopup: $showCalendarPopup,
                                showEventDetails: $showEventDetails
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 15)
                        } else if profileViewModel.friendshipStatus == .friends {
                            // User Events Section (for friends)
                            userEventsSection
                                .padding(.bottom, 15)
                        } else {
                            // Add to see events message (for non-friends)
                            addToSeeEventsSection
                                .padding(.horizontal)
                                .padding(.vertical, 20)
                        }
                    }
                    .padding(.horizontal)
                }
                .background(universalBackgroundColor)
                .navigationBarBackButtonHidden()
                .toolbar {
                    toolbarView
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
            refreshUserData()

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
                
                // Check friendship status if not viewing own profile
                if !isCurrentUserProfile, let currentUserId = userAuth.spawnUser?.id {
                    await profileViewModel.checkFriendshipStatus(
                        currentUserId: currentUserId,
                        profileUserId: user.id
                    )
                    print("checked friendship status")
                    
                    // If they're friends, fetch their events
                    if profileViewModel.friendshipStatus == .friends {
                        await profileViewModel.fetchUserUpcomingEvents(userId: user.id)
                    }
                }
                
                // Determine if back button should be shown based on navigation
                if !isCurrentUserProfile {
                    showBackButton = true
                }
            }
        }
        .onChange(of: userAuth.spawnUser) { newUser in
            // Update local state whenever spawnUser changes
            refreshUserData()
        }
        .onChange(of: profileViewModel.userSocialMedia) { newSocialMedia in
            // Update local state when social media changes
            if let socialMedia = newSocialMedia {
                whatsappLink = socialMedia.whatsappLink ?? ""
                instagramLink = socialMedia.instagramLink ?? ""
            }
        }
        .onChange(of: profileViewModel.friendshipStatus) { newStatus in
            // Fetch events when friendship status changes to friends
            if newStatus == .friends {
                Task {
                    await profileViewModel.fetchUserUpcomingEvents(userId: user.id)
                }
            }
        }
        // Add a timer to periodically refresh data
        .onReceive(
            Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
        ) { _ in
            refreshUserData()
            refreshFlag.toggle()  // Force the view to update
        }
        .accentColor(universalAccentColor)
        .toast(
            isShowing: $showNotification,
            message: notificationMessage,
            duration: 3.0
        )
        .sheet(isPresented: $showCalendarPopup) {
            InfiniteCalendarView(
                activities: profileViewModel.allCalendarActivities,
                isLoading: profileViewModel.isLoadingCalendar,
                onDismiss: { showCalendarPopup = false },
                onEventSelected: { activity in
                    handleEventSelection(activity)
                }
            )
        }
        .sheet(isPresented: $showImagePicker) {
            if selectedImage != nil {
                DispatchQueue.main.async {
                    isImageLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isImageLoading = false
                    }
                }
            }
        } content: {
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
        .sheet(isPresented: $showEventDetails) {
            if let event = profileViewModel.selectedEvent {
                // Use the same color scheme as EventCardView would
                let eventColor = event.isSelfOwned == true ? 
                    universalAccentColor : determineEventColor(for: event)
                
                EventDescriptionView(
                    event: event,
                    users: event.participantUsers,
                    color: eventColor,
                    userId: userAuth.spawnUser?.id ?? UUID()
                )
                .presentationDetents([.medium, .large])
            }
        }
        .navigationDestination(isPresented: $showTagDialog) {
            // Navigate to the new AddFriendToTagsView
            AddFriendToTagsView(friend: user)
        }
        .alert("Remove Friend", isPresented: $showRemoveFriendConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                if let currentUserId = userAuth.spawnUser?.id {
                    Task {
                        await profileViewModel.removeFriend(
                            currentUserId: currentUserId,
                            profileUserId: user.id
                        )
                    }
                }
            }
        } message: {
            Text("Are you sure you want to remove \(FormatterService.shared.formatName(user: user)) from your friends?")
        }
        .alert("Report User", isPresented: $showReportDialog) {
            TextField("Reason for report", text: $reportReason)
            Button("Cancel", role: .cancel) { 
                reportReason = ""
            }
            Button("Report", role: .destructive) {
                if let currentUserId = userAuth.spawnUser?.id, !reportReason.isEmpty {
                    Task {
                        await profileViewModel.reportUser(
                            reporterId: currentUserId,
                            reportedId: user.id,
                            reason: reportReason
                        )
                        reportReason = ""
                        
                        // Show success notification
                        notificationMessage = "User reported successfully"
                        showNotification = true
                    }
                }
            }
        }
        .alert("Block User", isPresented: $showBlockDialog) {
            TextField("Reason for blocking", text: $blockReason)
            Button("Cancel", role: .cancel) { 
                blockReason = ""
            }
            Button("Block", role: .destructive) {
                if let currentUserId = userAuth.spawnUser?.id, !blockReason.isEmpty {
                    Task {
                        await profileViewModel.blockUser(
                            blockerId: currentUserId,
                            blockedId: user.id,
                            reason: blockReason
                        )
                        blockReason = ""
                        
                        // Navigate back to previous screen after blocking
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        } message: {
            Text("Blocking this user will remove them from your friends list and they won't be able to see your profile or events.")
        }
        .sheet(isPresented: $showProfileMenu) {
            ProfileMenuView(
                user: user,
                showTagDialog: $showTagDialog,
                showRemoveFriendConfirmation: $showRemoveFriendConfirmation,
                showReportDialog: $showReportDialog,
                showBlockDialog: $showBlockDialog,
                isFriend: profileViewModel.friendshipStatus == .friends,
                copyProfileURL: copyProfileURL,
                shareProfile: shareProfile
            )
            .presentationDetents([.height(350)])
        }
        .onTapGesture {
            // Dismiss profile menu if it's showing
            if showProfileMenu {
                showProfileMenu = false
            }
        }
        .overlay(
            Group {
                if showProfileMenu {
                    // Dimmed background when menu is showing
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showProfileMenu = false
                        }
                }
            }
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
        let shareText =
            "Check out \(FormatterService.shared.formatName(user: user))'s profile on Spawn!"

        let activityItems: [Any] = [shareText, profileURL]
        let activityController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        // Present the activity controller
        if let windowScene = UIApplication.shared.connectedScenes.first
            as? UIWindowScene,
            let rootViewController = windowScene.windows.first?
                .rootViewController
        {
            rootViewController.present(
                activityController,
                animated: true,
                completion: nil
            )
        }
    }

    private func copyProfileURL() {
        let profileURL = "https://spawnapp.com/profile/\(user.id)"
        UIPasteboard.general.string = profileURL
        
        // Show notification toast
        notificationMessage = "Profile URL copied to clipboard"
        showNotification = true
    }

    private func removeInterest(_ interest: String) {
        Task {
            await profileViewModel.removeUserInterest(
                userId: user.id,
                interest: interest
            )
        }
    }

    // Add a function to refresh user data from UserAuthViewModel
    private func refreshUserData() {
        if isCurrentUserProfile, let currentUser = userAuth.spawnUser {
            username = currentUser.username
            name = currentUser.name ?? ""
        }
    }

    private func handleEventSelection(_ activity: CalendarActivityDTO) {
        // First close the calendar popup
        showCalendarPopup = false
        
        // Then fetch and show the event details
        Task {
            if let eventId = activity.eventId,
               let _ = await profileViewModel.fetchEventDetails(eventId: eventId) {
                await MainActor.run {
                    showEventDetails = true
                }
            }
        }
    }
    
    private func determineEventColor(for event: FullFeedEventDTO) -> Color {
        // Logic to determine event color based on friend tag or category
        if let hexCode = event.eventFriendTagColorHexCodeForRequestingUser, !hexCode.isEmpty {
            return Color(hex: hexCode)
        } else {
            return event.category.color()
        }
    }

    // Friend Action Buttons based on friendship status
    private var friendActionButtons: some View {
        Group {
            switch profileViewModel.friendshipStatus {
            case .none:
                // Add as Friend button
                Button(action: {
                    if let currentUserId = userAuth.spawnUser?.id {
                        Task {
                            await profileViewModel.sendFriendRequest(
                                fromUserId: currentUserId,
                                toUserId: user.id
                            )
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Add as Friend")
                            .bold()
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 8)
                    .frame(height: 32)
                    .frame(maxWidth: .infinity)
                    .background(universalAccentColor)
                    .cornerRadius(12)
                }
                
            case .requestSent:
                // Request Sent (disabled button)
                HStack {
                    Image(systemName: "clock")
                    Text("Request Sent")
                        .bold()
                }
                .font(.caption)
                .foregroundColor(Color.gray)
                .padding(.vertical, 24)
                .padding(.horizontal, 8)
                .frame(height: 32)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
                
            case .requestReceived:
                // Accept/Deny buttons
                HStack(spacing: 12) {
                    Button(action: {
                        if let requestId = profileViewModel.pendingFriendRequestId {
                            Task {
                                await profileViewModel.acceptFriendRequest(requestId: requestId)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Accept Request")
                                .bold()
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.vertical, 24)
                        .padding(.horizontal, 8)
                        .frame(height: 32)
                        .frame(maxWidth: .infinity)
                        .background(universalAccentColor)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        if let requestId = profileViewModel.pendingFriendRequestId {
                            Task {
                                await profileViewModel.declineFriendRequest(requestId: requestId)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Deny")
                                .bold()
                        }
                        .font(.caption)
                        .foregroundColor(universalAccentColor)
                        .padding(.vertical, 24)
                        .padding(.horizontal, 8)
                        .frame(height: 32)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(universalAccentColor, lineWidth: 1)
                        )
                    }
                }
                
            case .friends:
                // Share Profile button (same as in the original view)
                Button(action: {
                    shareProfile()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Profile")
                            .bold()
                    }
                    .font(.caption)
                    .foregroundColor(universalSecondaryColor)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 8)
                    .frame(height: 32)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(universalSecondaryColor, lineWidth: 1)
                    )
                }
                
            default:
                EmptyView()
            }
        }
    }
    
    // User Events Section for friend profiles
    private var userEventsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming Events by \(FormatterService.shared.formatFirstName(user: user))")
                .font(.headline)
                .foregroundColor(universalAccentColor)
                .padding(.horizontal)
            
            if profileViewModel.isLoadingUserEvents {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if profileViewModel.userEvents.isEmpty {
                Text("No upcoming events")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(profileViewModel.userEvents) { event in
                            EventCardView(
                                userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
                                event: event,
                                color: event.isSelfOwned == true ? universalAccentColor : determineEventColor(for: event),
                                callback: { selectedEvent, color in
                                    profileViewModel.selectedEvent = selectedEvent
                                    showEventDetails = true
                                }
                            )
                            .frame(width: 300, height: 180)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            HStack {
                Spacer()
                Button(action: {
                    // Navigate to all events by this user
                }) {
                    Text("Show All")
                        .font(.subheadline)
                        .foregroundColor(universalSecondaryColor)
                }
                .padding(.trailing)
            }
        }
    }
    
    // "Add to see events" section for non-friends
    private var addToSeeEventsSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 28))
                .foregroundColor(Color.gray.opacity(0.7))
            
            Text("Add \(FormatterService.shared.formatFirstName(user: user)) to see their upcoming spawns!")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.gray)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Toolbar View
extension ProfileView {
	    private var toolbarView: some View {
        // Name and Username - make this more reactive to changes
        ProfileNameView(
            user: user,
            refreshFlag: $refreshFlag
        )
    }
}

// MARK: - Profile Action Buttons
extension ProfileView {
    private var profileActionButtons: some View {
        HStack(spacing: 12) {
            if isCurrentUserProfile {
                NavigationLink(
                    destination: EditProfileView(
                        userId: user.id,
                        profileViewModel: profileViewModel
                    )
                ) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit Profile")
                            .bold()
                    }
                    .font(.caption)
                    .foregroundColor(universalSecondaryColor)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 8)
                    .frame(height: 32)
                    .frame(maxWidth: .infinity)
                }
                .navigationBarBackButtonHidden(true)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(universalSecondaryColor, lineWidth: 1)
                )
            }

            Button(action: {
                shareProfile()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Profile")
                        .bold()
                }
                .font(.caption)
                .foregroundColor(universalSecondaryColor)
                .padding(.vertical, 24)
                .padding(.horizontal, 8)
                .frame(height: 32)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(universalSecondaryColor, lineWidth: 1)
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
                    name = currentUser.name ?? ""
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
            name: name
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
            name = updatedUser.name ?? ""
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
        ZStack(alignment: .top) {
            // Interests content
            Group {
                if profileViewModel.isLoadingInterests {
                    interestsLoadingView
                } else {
                    interestsContentView
                }
            }
            .padding(.top, 24)  // Add padding to push content below the header

            // Position the header to be centered on the top border
            interestsSectionHeader
                .padding(.leading, 6)
            //                .offset() // Align with the top border
        }
    }

    private var interestsSectionHeader: some View {
        HStack {
            Text("Interests + Hobbies")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(universalTertiaryColor, lineWidth: 1)
                )
                .background(universalTertiaryColor)
                .clipShape(Capsule())

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
            if let whatsappLink = profileViewModel.userSocialMedia?
                .whatsappLink, !whatsappLink.isEmpty
            {
                Image("whatsapp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-8))
                    .onTapGesture {
                        openSocialMediaLink(
                            platform: "WhatsApp",
                            link: whatsappLink
                        )
                    }
            }

            if let instagramLink = profileViewModel.userSocialMedia?
                .instagramLink, !instagramLink.isEmpty
            {
                Image("instagram")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(8))
                    .onTapGesture {
                        openSocialMediaLink(
                            platform: "Instagram",
                            link: instagramLink
                        )
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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        // Use a simple LazyVGrid for consistent layout
                        LazyVGrid(
                            columns: [
                                GridItem(
                                    .adaptive(minimum: 80, maximum: 150),
                                    spacing: 8
                                )
                            ],
                            alignment: .leading,
                            spacing: 8
                        ) {
                            ForEach(profileViewModel.userInterests, id: \.self)
                            { interest in
                                interestChip(interest: interest)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(height: profileViewModel.userInterests.isEmpty ? 100 : 140)
        .padding(.horizontal)
        .padding(.top, 5)
    }

    private var emptyInterestsView: some View {
        Text("No interests added yet.")
            .foregroundColor(.gray)
            .italic()
            .padding()
            .padding(.top, 12)
    }

    private func interestChip(interest: String) -> some View {
        Text(interest)
            .font(.subheadline)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .foregroundColor(universalAccentColor)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            .overlay(
                isCurrentUserProfile && editingState == .save
                    ? HStack {
                        Spacer()
                        Button(action: {
                            removeInterest(interest)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .offset(x: 5, y: -8)
                    } : nil
            )
    }
}

// MARK: - User Stats Section
extension ProfileView {
    private var userStatsSection: some View {
        HStack(spacing: 35) {
            VStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)

                Text("\(profileViewModel.userStats?.peopleMet ?? 0)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(universalAccentColor)

                Text("People\nmet")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }

            VStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)

                Text("\(profileViewModel.userStats?.spawnsMade ?? 0)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(universalAccentColor)

                Text("Spawns\nmade")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }

            VStack(spacing: 4) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)

                Text("\(profileViewModel.userStats?.spawnsJoined ?? 0)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(universalAccentColor)

                Text("Spawns\njoined")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Weekly Calendar
extension ProfileView {
    private var weeklyCalendarView: some View {
        VStack(spacing: 8) {
            // Month and year title
            Text(monthYearString())
                .font(.subheadline)
                .foregroundColor(universalAccentColor)
                .padding(.vertical, 5)

            // Days of week header
            HStack(spacing: 0) {
                ForEach(Array(zip(0..<weekDays.count, weekDays)), id: \.0) { index, day in
                    Text(day)
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
            }

            if profileViewModel.isLoadingCalendar {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                // Calendar grid (clickable to show popup)
                VStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { col in
                                if let dayActivities = getDayActivities(row: row, col: col) {
                                    if dayActivities.isEmpty {
                                        // Empty day cell
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(height: 32)
                                    } else {
                                        // Mini day cell with multiple activities
                                        MiniDayCell(activities: dayActivities)
                                            .onTapGesture {
                                                handleDaySelection(activities: dayActivities)
                                            }
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 32)
                                }
                            }
                        }
                    }
                }
                .onTapGesture {
                    // Load all calendar activities before showing the popup
                    Task {
                        await profileViewModel.fetchAllCalendarActivities()
                        await MainActor.run {
                            showCalendarPopup = true
                        }
                    }
                }
            }
        }
        .onAppear {
            fetchCalendarData()
        }
        .sheet(isPresented: $showEventDetails) {
            if let event = profileViewModel.selectedEvent {
                // Use the same color scheme as EventCardView would
                let eventColor = event.isSelfOwned == true ? 
                    universalAccentColor : determineEventColor(for: event)
                
                EventDescriptionView(
                    event: event,
                    users: event.participantUsers,
                    color: eventColor,
                    userId: userAuth.spawnUser?.id ?? UUID()
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func handleDaySelection(activities: [CalendarActivityDTO]) {
        if activities.count == 1 {
            // If only one activity, directly open it
            handleEventSelection(activities[0])
        } else if activities.count > 1 {
            // If multiple activities, show day's events in a sheet
            Task {
                await profileViewModel.fetchAllCalendarActivities()
                await MainActor.run {
                    showDayEvents(activities: activities)
                }
            }
        }
    }
    
    private func showDayEvents(activities: [CalendarActivityDTO]) {
        // Present a sheet with EventCardViews for each activity
        let sheet = UIViewController()
        let hostingController = UIHostingController(rootView: DayEventsView(
            activities: activities,
            onDismiss: {
                sheet.dismiss(animated: true)
            },
            onEventSelected: { activity in
                sheet.dismiss(animated: true) {
                    self.handleEventSelection(activity)
                }
            }
        ))
        
        sheet.addChild(hostingController)
        hostingController.view.frame = sheet.view.bounds
        sheet.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: sheet)
        
        // Set up sheet presentation controller
        if let presentationController = sheet.presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
            presentationController.prefersGrabberVisible = true
        }
        
        // Present the sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(sheet, animated: true)
        }
    }
    
    // Get array of activities for a specific day cell
    private func getDayActivities(row: Int, col: Int) -> [CalendarActivityDTO]? {
        // Convert the original single-activity grid to an array of activities per cell
        let activity = profileViewModel.calendarActivities[row][col]
        
        if activity == nil {
            return nil
        }
        
        // Find all activities for this day by date checking
        if let firstActivity = activity {
            let day = Calendar.current.component(.day, from: firstActivity.date)
            let month = Calendar.current.component(.month, from: firstActivity.date)
            let year = Calendar.current.component(.year, from: firstActivity.date)
            
            // Filter all activities matching this date
            return profileViewModel.allCalendarActivities.filter { act in
                let actDay = Calendar.current.component(.day, from: act.date)
                let actMonth = Calendar.current.component(.month, from: act.date)
                let actYear = Calendar.current.component(.year, from: act.date)
                
                return actDay == day && actMonth == month && actYear == year
            }
        }
        
        return []
    }

    private var weekDays: [String] {
        ["S", "M", "T", "W", "T", "F", "S"]
    }

    private func fetchCalendarData() {
        Task {
            await profileViewModel.fetchCalendarActivities(
                month: currentMonth,
                year: currentYear
            )
            // Also fetch all activities to have them ready
            await profileViewModel.fetchAllCalendarActivities()
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
}

// Helper struct for the mini day cell in the profile view
struct MiniDayCell: View {
    let activities: [CalendarActivityDTO]
    
    private var gradientColors: [Color] {
        // Get up to 3 unique colors from activities
        let colors = activities.prefix(3).compactMap { activity -> Color? in
            if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
                return Color(hex: colorHex)
            } else if let category = activity.eventCategory {
                return category.color()
            }
            return nil
        }
        
        // If no colors found, return default gray
        if colors.isEmpty {
            return [Color.gray.opacity(0.5)]
        }
        
        // If only one color, use it with different opacity
        if colors.count == 1 {
            return [colors[0].opacity(0.7), colors[0].opacity(0.9)]
        }
        
        return colors
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 32)
            
            if activities.count <= 4 {
                // Show up to 4 icons in a grid
                let columns = [
                    GridItem(.flexible(), spacing: 1),
                    GridItem(.flexible(), spacing: 1)
                ]
                
                LazyVGrid(columns: columns, spacing: 1) {
                    ForEach(activities.prefix(4), id: \.id) { activity in
                        activityIcon(for: activity)
                            .foregroundColor(.white)
                            .font(.system(size: 10))
                    }
                }
                .padding(2)
            } else {
                // Show 2 icons + overflow indicator
                HStack(spacing: 2) {
                    ForEach(0..<2, id: \.self) { index in
                        if index < activities.count {
                            activityIcon(for: activities[index])
                                .foregroundColor(.white)
                                .font(.system(size: 10))
                        }
                    }
                    
                    Text("+\(activities.count - 2)")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private func activityColor(for activity: CalendarActivityDTO) -> Color {
        // First check if activity has a custom color hex code
        if let colorHexCode = activity.colorHexCode, !colorHexCode.isEmpty {
            return Color(hex: colorHexCode)
        }
        
        // Fallback to category color
        guard let category = activity.eventCategory else {
            return Color.gray.opacity(0.6) // Default color for null category
        }
        return category.color()
    }
    
    private func activityIcon(for activity: CalendarActivityDTO) -> some View {
        Group {
            // If we have an icon from the backend, use it directly
            if let icon = activity.icon, !icon.isEmpty {
                Text(icon)
                    .font(.system(size: 10))
            } else {
                // Fallback to system icon from the EventCategory enum
                Image(systemName: activity.eventCategory?.systemIcon() ?? "star.fill")
                    .font(.system(size: 10))
            }
        }
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

// Add ProfileMenuView at the end of the file
// ProfileMenuView is now in its own file: ProfileMenuView.swift
