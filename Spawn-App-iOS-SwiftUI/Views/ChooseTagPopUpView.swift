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
                    profilePictureView(for: friend)
                    
                    userInfoView(for: friend)
                    
                    Text("Select your friend tags below")
                        .foregroundColor(universalAccentColor)
                        .frame(maxWidth: .infinity)
                    
                    //TODO: show tags
                    tagListView(for: viewModel)
                    
                    //TODO: add button for each tag, when clicked will add to viewModel.tags
                    //TODO: done button, when clicked call viewmodel.AddTagsToFriend
                    doneButton(for: friend, viewModel: viewModel, closeCallback: closeCallback)
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
    VStack {
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
                .frame(width: 70, height: 70)
        }
    }
    .frame(maxWidth: .infinity)
}

private func userInfoView(for friend: User) -> some View {
    VStack(spacing: 4) {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundColor(universalAccentColor)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

            Text(friend.username)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(universalAccentColor)
        }

        let fullName = FormatterService.shared.formatName(user: friend)
        Text(fullName.isEmpty ? "Unknown" : fullName)
            .font(.system(size:12))
            .foregroundColor(universalAccentColor)
    }
    .frame(maxWidth: .infinity)
}

private func tagListView(for viewModel: ChooseTagPopUpViewModel) -> some View {
    VStack(spacing: 10) {
        ForEach(viewModel.tags, id: \.self) { tagId in
            Button(action: {
                viewModel.toggleTagSelection(tagId)
            }) {
                Text("Tag \(tagId.uuidString.prefix(6))")
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(viewModel.selectedTags.contains(tagId) ? universalAccentColor : Color.gray.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    .frame(maxWidth: .infinity)
}

private func doneButton(for friend: User, viewModel: ChooseTagPopUpViewModel, closeCallback: @escaping () -> Void) -> some View {
    Button(action: {
        Task {
            await viewModel.AddTagsToFriend(friendUserId: friend.id, friendTagIds: Array(viewModel.selectedTags))
            closeCallback()
        }
    }) {
        Text("done")
            .font(.system(size: 18, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(universalAccentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
    .padding(.top, 5)
}
