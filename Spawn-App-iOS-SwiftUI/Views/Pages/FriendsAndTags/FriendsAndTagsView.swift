//
//  FriendsAndTagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/24/24.
//

import SwiftUI

struct FriendsAndTagsView: View {
    let user: BaseUserDTO

    // for add friend to tag drawer:
    @State private var showAddFriendToTagButtonPressedView: Bool = false
    @State private var selectedFriendTagId: UUID? = nil
    @State private var tagsViewModel: TagsViewModel? = nil

    init(user: BaseUserDTO) {
        self.user = user
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        FriendRequestNavButtonView
                        FriendTagNavButtonView
                        Spacer()
                    }
                    .padding(.horizontal)

                    FriendsTabView(user: user)

                }
                .padding()
                .background(universalBackgroundColor)
                .navigationBarHidden(true)
            }
        }
        .sheet(isPresented: $showAddFriendToTagButtonPressedView) {
            if let friendTagIdForSheet = selectedFriendTagId {
                AddFriendToTagView(
                    userId: user.id,
                    friendTagId: friendTagIdForSheet,
                    closeCallback: closeSheet
                )
                .compatiblePresentationDragIndicator(.visible)
                .compatiblePresentationDetents([.height(400)])
            }
        }
    }

    func closeSheet() {
        showAddFriendToTagButtonPressedView = false

        // Re-fetch tags after closing the sheet
        Task {
            await tagsViewModel?.fetchTags()
        }
    }
}

struct BaseFriendNavButtonView: View {
    var iconImageName: String
    var topText: String
    var bottomText: String

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text(topText)
                        .onestSubheadline()
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.bottom, 6)
                    Spacer()
                }
                HStack {
                    Text(bottomText)
                        .onestSmallText()
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: true, vertical: false)
                        .lineLimit(1)
                    Spacer()
                }
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.leading, 8)
            .padding(.vertical, 8)
            // TODO DANIEL A: insert logic here to get from view model the num of friend requests, like in Figma
            Image(iconImageName)
                .resizable()
                .frame(width: 50, height: 50)
        }
        .background(universalSecondaryColor)
        .cornerRadius(12)
    }
}

extension FriendsAndTagsView {
    var FriendRequestNavButtonView: some View {
        NavigationLink(destination: {
            FriendRequestsView(userId: user.id)
        }) {
            BaseFriendNavButtonView(
                iconImageName: "friend_request_icon",
                topText: "Friend Requests",
                bottomText: "Accept or Deny"
            )
        }
    }

    var FriendTagNavButtonView: some View {
        NavigationLink(destination: {
            TagsTabView(
                userId: user.id,
                addFriendToTagButtonPressedCallback: {
                    friendTagId in
                    selectedFriendTagId = friendTagId
                    showAddFriendToTagButtonPressedView = true
                }
            )
        }) {
            BaseFriendNavButtonView(
                iconImageName: "friend_tag_icon",
                topText: "Friend Tags",
                bottomText: "Create or Edit"
            )
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    FriendsAndTagsView(user: .danielAgapov).environmentObject(appCache)
}
