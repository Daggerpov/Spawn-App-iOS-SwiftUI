//
//  InviteView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import SwiftUI

struct InviteView: View {
	let user: User

	//TODO: fix the friendtag toggle to look like figma design
	@State private var selectedTab: FriendTagToggle = .friends // TODO DANIEL: change back to tags later

	init(user: User) {
		self.user = user
	}

	var body: some View {
		NavigationStack {
			VStack(spacing: 20) {
				header
				if selectedTab == .friends {
					InviteFriendsView(user: user)
				} else {
					InviteTagsView(user: user)
				}
			}
			.padding()
			.background(universalBackgroundColor)
		}
	}
}

private extension InviteView {
	var header: some View {
		HStack {
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
	InviteView(user: .danielLee)
}
