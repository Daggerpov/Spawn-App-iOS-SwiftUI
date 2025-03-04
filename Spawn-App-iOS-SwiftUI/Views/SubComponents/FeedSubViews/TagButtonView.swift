//
//  TagButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import SwiftUI

struct TagButtonView: View {
	let tag: FriendTag
	@Binding var activeTag: FriendTag?  // Make activeTag optional
	var animation: Namespace.ID

	var body: some View {
		Button(action: {
			withAnimation(.easeIn) {
				activeTag = tag
			}
		}) {
			Text(tag.displayName)
				.font(.callout)
				.foregroundColor(
                    activeTag == tag ? universalPassiveColor : universalAccentColor
				)
				.padding(.vertical, 8)
				.padding(.horizontal, 15)
				.background {
					Capsule()
						.fill(activeTag == tag ? universalAccentColor : universalPassiveColor)
						.matchedGeometryEffect(
							id: "ACTIVETAG_\(tag.displayName)", in: animation)
				}
		}
		.buttonStyle(.plain)
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @Namespace var animation: Namespace.ID
	@Previewable @State var tag: FriendTag? = FriendTag.close
	TagButtonView(tag: FriendTag.close, activeTag: $tag, animation: animation)
}
