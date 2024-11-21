//
//  FriendListingView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

// TODO: refactor this heavily copy-pasted code I wrote later - Daniel
struct FriendListingView: View {
    @ObservedObject var viewModel: FriendListingViewModel
    var person: User
    
    init(person: User, user: User, isFriend: Bool) {
        self.person = person
        self.viewModel = FriendListingViewModel(person: person, user: user, isFriend: isFriend)
    }
    var body: some View {
        Group{
            if viewModel.isFriend {
                isFriendView
            } else {
                isNotFriendView
            }
        }
    }
}

extension FriendListingView {
    var isFriendView: some View {
        HStack{
            Image(person.profilePicture ?? "person.crop.circle.fill")
                .ProfileImageModifier(imageType: .friendsListView)
            VStack{
                HStack{
                    Image(systemName: "star.fill")
                    Text(person.username)
                        .bold()
                        .font(.headline)
                    Spacer()
                }
                .padding(.leading, 10)
                .padding(.trailing, 16)
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
                                    .fill(Color(friendTag.colorHexCode))
                            )
                    }
                    Spacer()
                }
                .padding(.leading, 10)
                
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(universalAccentColor)
        .cornerRadius(universalRectangleCornerRadius)
    }
    
    var isNotFriendView: some View {
        // not a friend
        HStack{
            HStack{
                Image(person.profilePicture ?? "person.crop.circle.fill")
                    .ProfileImageModifier(imageType: .friendsListView)
                
                VStack{
                    HStack{
                        Image(systemName: "star.fill")
                        Text(person.username)
                            .bold()
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.leading, 10)
                    .padding(.trailing, 16)
                    .font(.subheadline)
                    .foregroundColor(universalBackgroundColor)
                    HStack{
                        Text(viewModel.formattedFriendName)
                            .bold()
                            .padding(.leading, 10)
                            .padding(.trailing, 16)
                            .padding(.vertical, 0.25)
                            .font(.headline)
                            .foregroundColor(universalBackgroundColor)
                        Spacer()
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(universalAccentColor)
            .cornerRadius(universalRectangleCornerRadius)
            Spacer()
            Circle()
                .CircularButton(systemName: "person.2.badge.plus.fill", buttonActionCallback: {
                    viewModel.addFriend()
                }, width: 25, height: 20, frameSize: 45)
                .padding(.leading, 10)
        }
    }
}
