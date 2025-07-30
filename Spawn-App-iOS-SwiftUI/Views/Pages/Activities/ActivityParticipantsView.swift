import SwiftUI

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
        VStack(spacing: 0) {
            headerView
            
            // Participants content that takes remaining space
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hostSection
                    participantsSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, isExpanded ? 20 : 85) // Increased to match chatroom padding for visibility
            }
        }
        .fullScreenCover(isPresented: $showProfile) {
            if let selectedUser = selectedUser {
                ProfileView(user: selectedUser)
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            backButton
            Spacer()
            titleText
            Spacer()
            invisibleBalanceButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    private var backButton: some View {
        Button(action: {
            onBack()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var titleText: some View {
        Text("Who's Coming?")
            .font(Font.custom("Onest", size: 20).weight(.semibold))
            .foregroundColor(.white)
    }
    
    private var invisibleBalanceButton: some View {
        Button(action: {}) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.clear)
        }
        .disabled(true)
    }
    
    private var hostSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Host")
                .font(Font.custom("Onest", size: 16).weight(.medium))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 12) {
                // Host avatar
                if let profilePictureUrl = activity.creatorUser.profilePicture, let url = URL(string: profilePictureUrl) {
                    CachedProfileImage(
                        userId: activity.creatorUser.id,
                        url: url,
                        imageType: .participantsDrawer
                    )
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(activity.creatorUser.name?.first ?? activity.creatorUser.username?.first ?? "?").uppercased())
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.creatorUser.name ?? "Host")
                        .font(Font.custom("Onest", size: 16).weight(.bold))
                        .foregroundColor(.white)
                    Text("@\(activity.creatorUser.username ?? "host")")
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
                navigateToUserProfile(activity.creatorUser)
            }
            .contentShape(Rectangle()) // Ensure the entire area is tappable
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
                    HStack(spacing: 12) {
                        // Participant avatar
                        if let profilePictureUrl = participant.profilePicture, let url = URL(string: profilePictureUrl) {
                            CachedProfileImage(
                                userId: participant.id,
                                url: url,
                                imageType: .participantsDrawer
                            )
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(participant.name?.first ?? participant.username?.first ?? "?").uppercased())
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(participant.name ?? "Participant")
                                .font(Font.custom("Onest", size: 16).weight(.bold))
                                .foregroundColor(.white)
                            Text("@\(participant.username ?? "user")")
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
                        navigateToUserProfile(participant)
                    }
                    .contentShape(Rectangle()) // Ensure the entire area is tappable
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

// MARK: - Standalone Participants View (for sheets/full screen presentation)
struct ActivityParticipantsView: View {
    let activity: FullFeedActivityDTO
    let onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        onDismiss()
                    }
                
                // Main participants container
                VStack(spacing: 0) {
                    handleBar
                    headerView
                    
                    // Participants content that takes remaining space
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            hostSection
                            participantsSection
                        }
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
    
    private var handleBar: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.white.opacity(0.6))
            .frame(width: 50, height: 4)
            .padding(.top, 8)
            .padding(.bottom, 12)
    }
    
    private var headerView: some View {
        HStack {
            backButton
            Spacer()
            titleText
            Spacer()
            invisibleBalanceButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    private var backButton: some View {
        Button(action: {
            onDismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var titleText: some View {
        Text("Who's Coming?")
            .font(Font.custom("Onest", size: 20).weight(.semibold))
            .foregroundColor(.white)
    }
    
    private var invisibleBalanceButton: some View {
        Button(action: {}) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.clear)
        }
        .disabled(true)
    }
    
    private var hostSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Host")
                .font(Font.custom("Onest", size: 16).weight(.medium))
                .foregroundColor(.white.opacity(0.8))
            
            HStack(spacing: 12) {
                // Host avatar
                if let profilePictureUrl = activity.creatorUser.profilePicture, let url = URL(string: profilePictureUrl) {
                    CachedProfileImage(
                        userId: activity.creatorUser.id,
                        url: url,
                        imageType: .participantsDrawer
                    )
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(String(activity.creatorUser.name?.first ?? activity.creatorUser.username?.first ?? "?").uppercased())
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.creatorUser.name ?? "Host")
                        .font(Font.custom("Onest", size: 16).weight(.bold))
                        .foregroundColor(.white)
                    Text("@\(activity.creatorUser.username ?? "host")")
                        .font(Font.custom("Onest", size: 14).weight(.medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.2))
            .cornerRadius(12)
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
                    HStack(spacing: 12) {
                        // Participant avatar
                        if let profilePictureUrl = participant.profilePicture, let url = URL(string: profilePictureUrl) {
                            CachedProfileImage(
                                userId: participant.id,
                                url: url,
                                imageType: .participantsDrawer
                            )
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(participant.name?.first ?? participant.username?.first ?? "?").uppercased())
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(participant.name ?? "Participant")
                                .font(Font.custom("Onest", size: 16).weight(.bold))
                                .foregroundColor(.white)
                            Text("@\(participant.username ?? "user")")
                                .font(Font.custom("Onest", size: 14).weight(.medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
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