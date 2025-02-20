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

	// for add friend to tag popup:
	@State private var showAddFriendToTagButtonPressedPopupView: Bool = false
	@State private var popupOffset: CGFloat = 1000
	@State private var selectedFriendTagId: UUID? = nil

	init(user: User, source: BackButtonSourcePageType) {
		self.user = user
		self.source = source
	}

	var body: some View {
		ZStack {
			NavigationStack {
				VStack(spacing: 20) {
					header
					if selectedTab == .friends {
						FriendsTabView(user: user)
					} else {
						TagsTabView(
							userId: user.id,
							addFriendToTagButtonPressedCallback: {
								friendTagId in
								showAddFriendToTagButtonPressedPopupView = true
								selectedFriendTagId = friendTagId
							})
					}
				}
				.padding()
				.background(universalBackgroundColor)
				.navigationBarHidden(true)
				.dimmedBackground(
					isActive: showAddFriendToTagButtonPressedPopupView)
			}
			if showAddFriendToTagButtonPressedPopupView {
				addFriendToTagButtonPopupView
			}
		}
	}
	func closePopup() {
		popupOffset = 1000
		showAddFriendToTagButtonPressedPopupView = false
	}
}

extension FriendsView {
	var addFriendToTagButtonPopupView: some View {
		Group {
			if let friendTagIdForPopup = selectedFriendTagId {
				ZStack {
					Color(.black)
						.opacity(0.5)
						.onTapGesture {
							closePopup()
						}

					AddFriendToTagView(
						userId: user.id, friendTagId: friendTagIdForPopup,
						closeCallback: closePopup
					)
					.offset(x: 0, y: popupOffset)
					.onAppear {
						popupOffset = 0
					}
					.padding(.horizontal)
					.padding(.vertical, 250)
				}
				.ignoresSafeArea()
			}
		}
	}

	fileprivate var header: some View {
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
#Preview {
	FriendsView(user: .danielAgapov, source: .feed)
}
