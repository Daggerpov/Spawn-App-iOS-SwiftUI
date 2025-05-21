//
//  ProfileNameView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Lee on 11/09/24.
//

import SwiftUI

struct ProfileNameView: View {
    let user: BaseUserDTO
    let isCurrentUserProfile: Bool
    let userAuth: UserAuthViewModel
    let refreshFlag: Bool
    
    var body: some View {
        Group {
            if isCurrentUserProfile,
                let currentUser = userAuth.spawnUser
            {
                // For the current user, always display the latest from userAuth
                Text(
                    FormatterService.shared.formatName(
                        user: currentUser
                    )
                )
                .font(.title3)
                .bold()
                .foregroundColor(universalAccentColor)

                Text("@\(currentUser.username)")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                    .padding(.bottom, 5)
            } else {
                // For other users, use the passed-in user
                Text(
                    FormatterService.shared.formatName(
                        user: user
                    )
                )
                .font(.title3)
                .bold()
                .foregroundColor(universalAccentColor)

                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                    .padding(.bottom, 5)
            }
        }
        .id(refreshFlag)  // Force refresh when flag changes
    }
}

#Preview {
    ProfileNameView(
        user: BaseUserDTO.danielAgapov,
        isCurrentUserProfile: true,
        userAuth: UserAuthViewModel.shared,
        refreshFlag: false
    )
} 