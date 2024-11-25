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
                Image(profilePictureString)
                    .ProfileImageModifier(imageType: .chatMessage)
                    .font(.system(size: 20))
            }
            Image(systemName: "star.fill")
                .font(.system(size: 10))
            Text(friend.username)
                .font(.subheadline)
            Spacer()
            Button(action: action) {
                Image(systemName: "xmark")
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
    }
}
