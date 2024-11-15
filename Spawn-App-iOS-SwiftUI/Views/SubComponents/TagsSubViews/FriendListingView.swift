//
//  FriendListingView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct FriendListingView: View {
    @ObservedObject var viewModel: FriendListingViewModel
    var friend: AppUser
    
    init(friend: AppUser, appUser: AppUser) {
        self.friend = friend
        self.viewModel = FriendListingViewModel(friend: friend, appUser: appUser)
    }
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
                HStack{
                    Image(systemName: "star.fill")
                    Text(friend.username)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)
                .font(.subheadline)
                .foregroundColor(universalBackgroundColor)
                HStack{
                    ForEach(viewModel.tagsForFriend) { friendTag in
                        // TODO: implement navigation from friend tag to friend tag view, which I'll do now, inside of "View Tags" popup
                        Text(friendTag.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundColor(.white) // Adjust text color if needed
                            .background(
                                Capsule()
                                    .fill(friendTag.color)
                            )
                    }
                    Spacer()
                }
                .padding(.leading, 20)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(universalAccentColor)
        .cornerRadius(universalRectangleCornerRadius)
    }
}
