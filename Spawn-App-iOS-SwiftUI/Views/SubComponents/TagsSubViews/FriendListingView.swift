//
//  FriendListingView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct FriendListingView: View {
    var friend: AppUser
    var body: some View {
        HStack{
            if let pfp = friend.profilePicture {
                pfp
                    .ProfileImageModifier(imageType: .friendsListView)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .ProfileImageModifier(imageType: .friendsListView)
            }
            VStack{
                
                Text(friend.username)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(universalBackgroundColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(universalAccentColor)
        .cornerRadius(universalRectangleCornerRadius)
    }
}
