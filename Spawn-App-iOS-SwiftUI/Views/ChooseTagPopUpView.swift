//
//  ChoosingTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Michael Tham on 23/1/25.
//

import SwiftUI

struct ChoosingTagPopupView: View {
    @ObservedObject var viewModel: ChooseTagPopUpViewModel
    var friend: User
    var userId: UUID
    var closeCallback: () -> Void
    
    init(friend: User, userId: UUID, closeCallback: @escaping () -> Void) {
        self.friend = friend
        self.userId = userId
        self.closeCallback = closeCallback
        self.viewModel = ChooseTagPopUpViewModel(
            userId: userId,
            apiService: MockAPIService.isMocking
                ? MockAPIService(userId: userId) : APIService())
    }
        
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // profile pic
                    profilePictureView(for: friend)
                    
                    // star with username
                    userNameView(for: friend)
                    
                    Text("Select your friend tags below")
                    
                    //TODO: show tags
                    
                    //TODO: add button for each tag, when clicked will add to viewModel.tags
                    //TODO: done button, when clicked call viewmodel.AddTagsToFriend
                }
                .frame(
                    minHeight: 300,
                    idealHeight: 340,
                    maxHeight: 380
                )
                .padding(20)
                .background(universalBackgroundColor)
                .cornerRadius(universalRectangleCornerRadius)
            }
            .scrollDisabled(true)  // to get fitting from `ScrollView`, without the actual scrolling
//            .onAppear {
//                Task {
//                    await viewModel.fetchFriendsToAddToTag(friendTagId: friendTagId)
//                }
//            }
        }
    //TODO: change onAppear await to viewModel.fetchTagsToAddToFriend
}

private func profilePictureView(for friend: User) -> some View {
    Group {
        if let pfpUrl = friend.profilePicture {
            AsyncImage(url: URL(string: pfpUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(universalAccentColor, lineWidth: 2))
                    .padding(.horizontal, 1)
            } placeholder: {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 70, height: 70)
            }
        } else {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
        }
    }
}

private func userNameView(for friend: User) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(universalAccentColor)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

            Text(friend.username)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(universalAccentColor)
        }

        let fullName = FormatterService.shared.formatName(user: friend)
        Text(fullName.isEmpty ? "Unknown" : fullName)
    }
}
