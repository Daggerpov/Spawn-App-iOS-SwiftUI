//
//  ProfilePictureView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/20/25.
//
import SwiftUI

struct ProfilePictureView: View {
    let user: BaseUserDTO
    let width: CGFloat = 28
    let height: CGFloat = 28
    @State var showProfile = false
    
    // Optional binding to control tab selection for current user navigation
    @Binding var selectedTab: TabType?
    
    // Check if this is the current user
    private var isCurrentUser: Bool {
        guard let currentUser = UserAuthViewModel.shared.spawnUser else { return false }
        return currentUser.id == user.id
    }
    
    init(user: BaseUserDTO, selectedTab: Binding<TabType?> = .constant(nil)) {
        self.user = user
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        VStack {
            if let pfpUrl = user.profilePicture {
                if MockAPIService.isMocking {
                    Image(pfpUrl)
                        .ProfileImageModifier(imageType: .activityParticipants)
                } else {
                    AsyncImage(url: URL(string: pfpUrl)) { image in
                        image.ProfileImageModifier(imageType: .activityParticipants)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: width, height: height)
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: width, height: height)
            }
        }
        .onTapGesture {
            if isCurrentUser && selectedTab != nil {
                // Navigate to profile tab for current user
                selectedTab = .profile
            } else {
                // Show full screen cover for other users
                showProfile = true
            }
        }
        .fullScreenCover(isPresented: $showProfile) {
            ProfileView(user: user)
        }
    }
}
