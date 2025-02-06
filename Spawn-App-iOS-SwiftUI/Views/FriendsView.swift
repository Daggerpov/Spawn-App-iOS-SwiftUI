//
//  FriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/24/24.
//

import SwiftUI

struct FriendsView: View {
    let user: User
	let source: BackButtonSourcePageType

    //TODO: fix the friendtag toggle to look like figma design
	@State private var selectedTab: FriendTagToggle = .friends

	init(user: User, source: BackButtonSourcePageType) {
        self.user = user
		self.source = source
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                header
                if selectedTab == .friends {
                    FriendsTabView(user: user)
                } else {
					TagsTabView(userId: user.id)
                }
            }
            .padding()
            .background(universalBackgroundColor)
            .navigationBarHidden(true)
        }
    }
}

private extension FriendsView {
    var header: some View {
        HStack {
			BackButton(user: user, source: source)
            Spacer()
            Picker("", selection: $selectedTab) {
                Text("friends")
                    .tag(FriendTagToggle.friends)
                //TODO: change color of text to universalAccentColor when selected and universalBackgroundColor when not

                Text("tags")
                    .tag(FriendTagToggle.tags)
                //TODO: change color of text to universalAccentColor when selected and universalBackgroundColor when not
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 150, height: 40)
            .background(
                RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                    .fill(universalAccentColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                    .stroke(universalBackgroundColor, lineWidth: 1)
            )
            .cornerRadius(universalRectangleCornerRadius)
            Spacer()
        }
        .padding(.horizontal)
    }
}

@available(iOS 17.0, *)
#Preview
{
	FriendsView(user: .danielAgapov, source: .feed)
}
