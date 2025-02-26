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
            VStack(alignment: .leading, spacing: 20) {
                profilePictureView(for: friend)
                
                userInfoView(for: friend)
                
                Text("Select your friend tags below")
                    .foregroundColor(universalAccentColor)
                    .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 20) {
                    tagListView(for: viewModel)
                    
                    //TODO: addTagButtonView
                }
                doneButton(for: friend, viewModel: viewModel, closeCallback: closeCallback)
            }
            .padding(20)
            .background(universalBackgroundColor)
            .cornerRadius(universalRectangleCornerRadius)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.85, maxHeight: 500)
            .shadow(radius: 10)
            
            .scrollDisabled(true)
            .onAppear {
                Task {
                    await viewModel.fetchTagsToAddToFriend(friendUserId: friend.id)
                }
            }
    }
}

private func profilePictureView(for friend: User) -> some View {
    ZStack {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(stops: [
                        Gradient.Stop(color: Color(red: 0.56, green: 0.39, blue: 0.91).opacity(0.6), location: 0.0),
                        Gradient.Stop(color: Color(red: 0.48, green: 0.74, blue: 0.9).opacity(0.3), location: 1.0),
                        Gradient.Stop(color: Color.clear, location: 1.2)
                    ]),
                    center: .center,
                    startRadius: 40,
                    endRadius: 60
                )
            )
            .frame(width: 90, height: 90)
            .blur(radius: 8)

        Image("Spawn_Glow")
            .resizable()
            .scaledToFill()
            .frame(width: 84, height: 84)
            .clipShape(Circle())
        
        if let profilePictureString = friend.profilePicture {
            if MockAPIService.isMocking {
                Image(profilePictureString)
                    .ProfileImageModifier(imageType: .choosingFriendTags)
            } else {
                AsyncImage(url: URL(string: profilePictureString)) {
                    image in
                    image
                        .ProfileImageModifier(
                            imageType: .choosingFriendTags)
                } placeholder: {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 80, height: 80)
                }
            }
        } else {
            Image(systemName: "person.crop.circle.fill")
                .ProfileImageModifier(imageType: .profilePage)
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
                .frame(width: 20, height: 20)
                .foregroundColor(universalAccentColor)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

            Text(friend.username)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(universalAccentColor)
        }

        let fullName = FormatterService.shared.formatName(user: friend)
        Text(fullName.isEmpty ? "Unknown" : fullName)
            .font(.system(size:12))
            .foregroundColor(universalAccentColor)
    }
    .frame(maxWidth: .infinity)
}

//TODO: add functionality where when tag selected, tag name shifts left and checkmark appears on right
private func tagListView(for viewModel: ChooseTagPopUpViewModel) -> some View {
    ScrollView {
        VStack(spacing: 10) {
            ForEach(viewModel.tags, id: \.self) { tagId in
                if let tag = FriendTag.mockTags.first(where: { $0.id == tagId }) {
                    Button(action: {
                        viewModel.toggleTagSelection(tagId)
                    }) {
                        Text(tag.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: tag.colorHexCode))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
    .frame(height: 200)
    .scrollIndicators(.hidden)
}

private func doneButton(for friend: User, viewModel: ChooseTagPopUpViewModel, closeCallback: @escaping () -> Void) -> some View {
    Button(action: {
        Task {
            await viewModel.AddTagsToFriend(friendUserId: friend.id, friendTagIds: Array(viewModel.selectedTags))
            closeCallback()
        }
    }) {
        Text("Done")
            .font(.system(size: 18, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(universalAccentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
    .padding(.top, 5)
}
