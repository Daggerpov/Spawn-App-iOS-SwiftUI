import SwiftUI

// MARK: - Shared Components

// Shared back button component
struct ParticipantsBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// Shared title text component
struct ParticipantsTitleText: View {
    var body: some View {
        Text("Who's Coming?")
            .font(Font.custom("Onest", size: 20).weight(.semibold))
            .foregroundColor(.white)
    }
}

// Shared invisible balance button for layout purposes
struct InvisibleBalanceButton: View {
    var body: some View {
        Button(action: {}) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.clear)
        }
        .disabled(true)
    }
}

// Shared header view component
struct ParticipantsHeaderView: View {
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            ParticipantsBackButton(action: onBack)
            Spacer()
            ParticipantsTitleText()
            Spacer()
            InvisibleBalanceButton()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

// MARK: - Shared User Item Component
struct UserItemView: View {
    let user: BaseUserDTO
    let onTap: (() -> Void)?
    
    init(user: BaseUserDTO, onTap: (() -> Void)? = nil) {
        self.user = user
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // User avatar
            if let profilePictureUrl = user.profilePicture, let url = URL(string: profilePictureUrl) {
                CachedProfileImage(
                    userId: user.id,
                    url: url,
                    imageType: .participantsDrawer
                )
            } else {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(user.name?.first ?? user.username?.first ?? "?").uppercased())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name ?? (user.id == UserAuthViewModel.shared.spawnUser?.id ? "You" : "User"))
                    .font(Font.custom("Onest", size: 16).weight(.bold))
                    .foregroundColor(.white)
                Text("@\(user.username ?? "user")")
                    .font(Font.custom("Onest", size: 14).weight(.medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
        .onTapGesture {
            onTap?()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Shared Participants Content
struct SharedParticipantsContent: View {
    @ObservedObject var activity: FullFeedActivityDTO
    let onUserTap: ((BaseUserDTO) -> Void)?
    
    init(activity: FullFeedActivityDTO, onUserTap: ((BaseUserDTO) -> Void)? = nil) {
        self.activity = activity
        self.onUserTap = onUserTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            hostSection
            participantsSection
        }
    }
    
    private var hostSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Host")
                .font(Font.custom("Onest", size: 16).weight(.medium))
                .foregroundColor(.white.opacity(0.8))
            
            UserItemView(user: activity.creatorUser) {
                onUserTap?(activity.creatorUser)
            }
        }
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let participantCount = activity.participantUsers?.count ?? 0
            Text("Going (\(participantCount))")
                .font(Font.custom("Onest", size: 16).weight(.medium))
                .foregroundColor(.white.opacity(0.8))
            
            if let participants = activity.participantUsers, !participants.isEmpty {
                ForEach(participants, id: \.id) { participant in
                    UserItemView(user: participant) {
                        onUserTap?(participant)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Text("No one has joined yet")
                        .font(Font.custom("Onest", size: 16).weight(.medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Invite friends to join your activity!")
                        .font(Font.custom("Onest", size: 14).weight(.medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}

// MARK: - Embedded Participants Content View (for use within drawers)
struct ParticipantsContentView: View {
    @ObservedObject var activity: FullFeedActivityDTO
    var backgroundColor: Color
    var isExpanded: Bool
    let onBack: () -> Void
    
    // Optional binding to control tab selection for current user navigation
    @Binding var selectedTab: TabType?
    
    // Callback to dismiss the drawer
    let onDismiss: () -> Void
    
    // State for other user profile navigation
    @State private var showProfile = false
    @State private var selectedUser: BaseUserDTO?
    
    // Check if a user is the current user
    private func isCurrentUser(_ user: BaseUserDTO) -> Bool {
        guard let currentUser = UserAuthViewModel.shared.spawnUser else { return false }
        return currentUser.id == user.id
    }
    
    // Navigation logic
    private func navigateToUserProfile(_ user: BaseUserDTO) {
        if isCurrentUser(user) && selectedTab != nil {
            // Navigate to profile tab for current user
            selectedTab = .profile
        } else {
            // Show full screen cover for other users
            selectedUser = user
            showProfile = true
        }
        // Dismiss the drawer when navigating to profiles
        onDismiss()
    }
    
    init(activity: FullFeedActivityDTO, backgroundColor: Color, isExpanded: Bool, onBack: @escaping () -> Void, selectedTab: Binding<TabType?> = .constant(nil), onDismiss: @escaping () -> Void = {}) {
        self.activity = activity
        self.backgroundColor = backgroundColor
        self.isExpanded = isExpanded
        self.onBack = onBack
        self._selectedTab = selectedTab
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ParticipantsHeaderView(onBack: onBack)
                    .padding(.top, isExpanded ? geometry.safeAreaInsets.top + 24 : 0)
                
                // Participants content that takes remaining space
                ScrollView {
                    SharedParticipantsContent(activity: activity) { user in
                        navigateToUserProfile(user)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, isExpanded ? 20 : 85) // Increased to match chatroom padding for visibility
                }
            }
        }
        .fullScreenCover(isPresented: $showProfile) {
            if let selectedUser = selectedUser {
                ProfileView(user: selectedUser)
            }
        }
    }
}

// MARK: - Standalone Participants View (for sheets/full screen presentation)
struct ActivityParticipantsView: View {
    let activity: FullFeedActivityDTO
    let onDismiss: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                (colorScheme == .dark ? Color.black.opacity(0.60) : Color.black.opacity(0.40))
                    .ignoresSafeArea()
                    .onTapGesture {
                        onDismiss()
                    }
                
                // Main participants container
                VStack(spacing: 0) {
                    ParticipantsHeaderView(onBack: onDismiss)
                    
                    // Participants content that takes remaining space
                    ScrollView {
                        SharedParticipantsContent(activity: activity)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                    }
                    
                    bottomHandle
                }
                .background(Color(red: 0.33, green: 0.42, blue: 0.93).opacity(0.80))
                .cornerRadius(20)
                .padding(.horizontal, 20)
                .padding(.top, geometry.safeAreaInsets.top + 16) // Dynamic safe area + extra padding
                .padding(.bottom, geometry.safeAreaInsets.bottom + 16) // Dynamic safe area + extra padding
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - View Components
    
    private var bottomHandle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.gray.opacity(0.6))
            .frame(width: 134, height: 5)
            .padding(.bottom, 8)
    }
}

#Preview {
    ActivityParticipantsView(
        activity: FullFeedActivityDTO.mockDinnerActivity,
        onDismiss: {}
    )
} 