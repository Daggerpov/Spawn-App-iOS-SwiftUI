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
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	InviteView(user: .danielAgapov)
}
