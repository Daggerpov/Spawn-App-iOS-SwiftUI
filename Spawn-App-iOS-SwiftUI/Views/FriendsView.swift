//
//  FriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/24/24.
//

import SwiftUI

struct FriendsView: View {
	let user: BaseUserDTO
	let source: BackButtonSourcePageType

	@State private var selectedTab: FriendTagToggle = .friends

	// for add friend to tag popup:
	@State private var showAddFriendToTagButtonPressedPopupView: Bool = false
	@State private var popupOffset: CGFloat = 1000
	@State private var selectedFriendTagId: UUID? = nil

	init(user: BaseUserDTO, source: BackButtonSourcePageType) {
		self.user = user
		self.source = source
	}

	var body: some View {
		ZStack {
			NavigationStack {
				VStack(spacing: 20) {
					HStack {
						BackButton(user: user, source: source)
						Spacer()
						FriendTagToggleView(selectedTab: $selectedTab)
						Spacer()
					}
					.padding(.horizontal)

					if selectedTab == .friends {
						FriendsTabView(user: user)
					} else {
						TagsTabView(
							userId: user.id,
							addFriendToTagButtonPressedCallback: {
								friendTagId in
								showAddFriendToTagButtonPressedPopupView = true
								selectedFriendTagId = friendTagId
							}
						)
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
}

@available(iOS 17.0, *)
#Preview {
	FriendsView(user: .danielAgapov, source: .feed)
}
