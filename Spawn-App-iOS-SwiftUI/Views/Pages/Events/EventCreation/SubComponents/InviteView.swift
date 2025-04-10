//
//  InviteView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import SwiftUI

struct InviteView: View {
	let user: BaseUserDTO

	@State private var selectedTab: FriendTagToggle = .friends

	init(user: BaseUserDTO) {
		self.user = user
	}

	var body: some View {
		NavigationStack {
			VStack(spacing: 20) {
				FriendTagToggleView(selectedTab: $selectedTab)

				if selectedTab == .friends {
					InviteFriendsView(user: user)
				} else {
					InviteTagsView(user: user)
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(universalBackgroundColor)
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
}

@available(iOS 17.0, *)
#Preview {
	InviteView(user: .danielAgapov)
}
