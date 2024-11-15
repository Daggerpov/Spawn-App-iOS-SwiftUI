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
                }
                .padding(.horizontal)
                .font(.subheadline)
                .foregroundColor(universalBackgroundColor)
                HStack{
                    ForEach(viewModel.tagsForFriend) { friendTag in
                        Text(friendTag.displayName)
                            .foregroundColor(friendTag.color)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(universalAccentColor)
        .cornerRadius(universalRectangleCornerRadius)
    }
}
