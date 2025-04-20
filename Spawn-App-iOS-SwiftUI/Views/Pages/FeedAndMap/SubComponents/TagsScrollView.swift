//
//  TagsScrollView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/23/24.
//

import SwiftUI

struct TagsScrollView: View {
	var tags: [FullFriendTagDTO]
	@Binding private var activeTag: FullFriendTagDTO?
	@Namespace private var animation: Namespace.ID

	init(tags: [FullFriendTagDTO], activeTag: Binding<FullFriendTagDTO?>) {
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

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	@Previewable @State var tag: FullFriendTagDTO? = FullFriendTagDTO.close
	TagsScrollView(tags: FullFriendTagDTO.mockTags, activeTag: $tag).environmentObject(appCache)
}
