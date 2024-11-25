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
            }
            Text(friend.username)
                .font(.subheadline)
            Spacer()
            Button(action: action) {
                Image(systemName: "xmark")
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal)
    }
}
