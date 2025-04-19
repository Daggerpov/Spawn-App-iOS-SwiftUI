//
//  FriendsAndTagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/24/24.
//

import SwiftUI

struct FriendsAndTagsView: View {
	let user: BaseUserDTO
	let source: BackButtonSourcePageType

	@State private var selectedTab: FriendTagToggle = .friends

	// for add friend to tag popup:
	@State private var showAddFriendToTagButtonPressedPopupView: Bool = false
	@State private var popupOffset: CGFloat = 1000
	@State private var selectedFriendTagId: UUID? = nil
	@State private var tagsViewModel: TagsViewModel? = nil

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
				.gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
					.onEnded { value in
						switch(value.translation.width, value.translation.height) {
							case (...0, -30...30): // left swipe
								if selectedTab == .friends {
									selectedTab = .tags
								}
							case (0..., -30...30): // right swipe
								if selectedTab == .tags {
									selectedTab = .friends
								}
							default: break
						}
					}
				)
			}
			if showAddFriendToTagButtonPressedPopupView {
				addFriendToTagButtonPopupView
			}
		}
	}
	func closePopup() {
		popupOffset = 1000
		showAddFriendToTagButtonPressedPopupView = false
		
		// Re-fetch tags after closing the popup
		Task {
			await tagsViewModel?.fetchTags()
		}
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
    @Previewable @StateObject var appCache = AppCache.shared
	FriendsAndTagsView(user: .danielAgapov, source: .feed).environmentObject(appCache)
}
