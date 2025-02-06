//
//  TagsScrollView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/23/24.
//

import SwiftUI

struct TagsScrollView: View {
    var tags: [FriendTag]
    @State private var activeTag: FriendTag?
    @Namespace private var animation: Namespace.ID

	init(tags: [FriendTag]) {
		self.tags = tags
		self._activeTag = State(initialValue: tags.first) // this will automatically null-check
	}

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tags, id: \.self) { tag in
					if activeTag != nil {
						TagButtonView(tag: tag, activeTag: $activeTag, animation: animation)
					}
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 16)
        }
    }
    
}
