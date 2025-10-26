//
//  ProfileNameView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileNameView: View {
    let user: Nameable
    @StateObject var userAuth = UserAuthViewModel.shared
    @Binding var refreshFlag: Bool
    
    // Check if this is the current user's profile
    var isCurrentUserProfile: Bool {
        if MockAPIService.isMocking {
            return true
        }
        guard let currentUser = userAuth.spawnUser else { return false }
        return currentUser.id == user.id
    }
    
    var body: some View {
        // Name and Username - make this more reactive to changes
        Group {
            if isCurrentUserProfile,
               let currentUser = userAuth.spawnUser
            {
				Text(
					FormatterService.shared.formatName(
						user: currentUser
					)
				)
				.font(.title3)
				.bold()
				.foregroundColor(universalAccentColor)
                				Text("@\(currentUser.username ?? "username")")
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
                				Text("@\(user.username ?? "username")")
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
        refreshFlag: .constant(false)
    )
} 
