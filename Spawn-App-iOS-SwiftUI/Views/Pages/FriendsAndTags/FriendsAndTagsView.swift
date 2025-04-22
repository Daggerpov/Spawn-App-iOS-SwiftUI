//
//  FriendsAndTagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/24/24.
//

import SwiftUI

struct FriendsAndTagsView: View {
	let user: BaseUserDTO
	@State private var selectedTab: FriendTagToggle = .friends

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
								selectedFriendTagId = friendTagId
								showAddFriendToTagButtonPressedView = true
							}
						)
					}

				}
				.padding()
				.background(universalBackgroundColor)
				.navigationBarHidden(true)
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
		}
		.sheet(isPresented: $showAddFriendToTagButtonPressedView) {
			if let friendTagIdForSheet = selectedFriendTagId {
				AddFriendToTagView(
					userId: user.id,
					friendTagId: friendTagIdForSheet,
					closeCallback: closeSheet
				)
				.presentationDragIndicator(.visible)
				.presentationDetents([.height(400)])
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

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	FriendsAndTagsView(user: .danielAgapov).environmentObject(appCache)
}
