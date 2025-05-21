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

    @StateObject var userAuth = UserAuthViewModel.shared
    @StateObject var profileViewModel: ProfileViewModel

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
        self._profileViewModel = StateObject(wrappedValue: ProfileViewModel(userId: user.id))
        self.username = user.username
        self.name = user.name ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .center, spacing: 15) {
                        // Profile Picture
                        ProfileHeaderView(
                            user: user,
                            selectedImage: $selectedImage,
                            showImagePicker: $showImagePicker,
                            isImageLoading: $isImageLoading,
                            isCurrentUserProfile: isCurrentUserProfile,
                            editingState: editingState
                        )
                        .padding(.top, 15)
                        
                        // Name and Username
                        ProfileNameView(
                            user: user,
                            isCurrentUserProfile: isCurrentUserProfile,
                            userAuth: userAuth,
                            refreshFlag: refreshFlag
                        )

                        // Profile Action Buttons
                        ProfileActionButtonsView(
                            user: user,
                            isCurrentUserProfile: isCurrentUserProfile,
                            profileViewModel: profileViewModel,
                            shareProfile: shareProfile
                        )
                        .padding(.horizontal, 25)
                        .padding(.bottom, 15)

                        // Edit Save Cancel buttons (only when editing)
                        if isCurrentUserProfile && editingState == .save {
                            ProfileEditButtonsView(
                                editingState: $editingState,
                                onCancel: cancelEditing,
                                onSave: { Task { await saveProfile() } },
                                isImageLoading: isImageLoading
                            )
                            .padding(.bottom, 5)
                        }

                        // Interests Section with Social Media Icons
                        ProfileInterestsView(
                            profileViewModel: profileViewModel, 
                            isCurrentUserProfile: isCurrentUserProfile,
                            editingState: editingState,
                            whatsappLink: $whatsappLink, 
                            instagramLink: $instagramLink,
                            onRemoveInterest: removeInterest,
                            openSocialMediaLink: openSocialMediaLink
                        )
                        .padding(.bottom, 15)

                        // User Stats
                        ProfileStatsView(userStats: profileViewModel.userStats)
                        .padding(.bottom, 15)

                        // Weekly Calendar View
                        ProfileCalendarView(
                            profileViewModel: profileViewModel,
                            currentMonth: $currentMonth,
                            currentYear: $currentYear,
                            showCalendarPopup: $showCalendarPopup,
                            handleDaySelection: handleDaySelection
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 15)
                    }
                    .padding(.horizontal)
                }
                .background(universalBackgroundColor)
                .navigationBarBackButtonHidden()
                .navigationBarItems(
                    trailing: NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(universalAccentColor)
                            .font(.title3)
                    }
                )
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
    
    private func cancelEditing() {
        // Revert to original values from userAuth.spawnUser
        if let currentUser = userAuth.spawnUser {
            username = currentUser.username
            name = currentUser.name ?? ""
            selectedImage = nil

            // Revert social media links
            if let socialMedia = profileViewModel.userSocialMedia {
                whatsappLink = socialMedia.whatsappLink ?? ""
                instagramLink = socialMedia.instagramLink ?? ""
            }
        }
        editingState = .edit
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
    
    private func determineEventColor(for event: FullFeedEventDTO) -> Color {
        // Logic to determine event color based on friend tag or category
        if let hexCode = event.eventFriendTagColorHexCodeForRequestingUser, !hexCode.isEmpty {
            return Color(hex: hexCode)
        } else {
            return event.category.color()
        }
    }
}

@available(iOS 17, *)
#Preview {
    ProfileView(user: BaseUserDTO.danielAgapov)
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
