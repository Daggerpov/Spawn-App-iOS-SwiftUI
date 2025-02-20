//
//  TagsScrollView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/23/24.
//

import SwiftUI

struct TagsScrollView: View {
	var tags: [FriendTag]
	@Binding private var activeTag: FriendTag?
	@Namespace private var animation: Namespace.ID

	init(tags: [FriendTag], activeTag: Binding<FriendTag?>) {
		self.tags = tags
		self._activeTag = activeTag
	}

	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 12) {
				ForEach(tags, id: \.self) { tag in
					TagButtonView(
						tag: tag, activeTag: $activeTag, animation: animation
					)
					.onAppear {
					}
				}
			}
			.padding(.top, 10)
			.padding(.horizontal, 16)
		}
	}

}
