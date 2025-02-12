//
//  FriendRow.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct FriendRow: View {
    var friend: User
    var action: () -> Void = {}

    var body: some View {
        HStack {
            if let profilePictureString = friend.profilePicture {
				// TODO: make async
                Image(profilePictureString)
					.ProfileImageModifier(imageType: .tagFriends)
            }
            Image(systemName: "star.fill")
                .font(.system(size: 10))
            Text(friend.username)
                .font(.headline)
            Spacer()
            Button(action: action) {
                Image(systemName: "xmark")
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
        .background(
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.black)
                        .opacity(0.3)
                }
            )
    }
}
