//
//  TagButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import SwiftUI

struct TagButtonView: View {
	let tag: FriendTag
	@Binding var activeTag: FriendTag? // Make activeTag optional
	var animation: Namespace.ID

	var body: some View {
		Button(action: {
			withAnimation(.easeIn) {
				activeTag = tag
			}
		}) {
			Text(tag.displayName)
				.font(.callout)
				.foregroundColor(activeTag == tag ? .white : universalAccentColor)
				.padding(.vertical, 8)
				.padding(.horizontal, 15)
				.background {
					Capsule()
						.fill(activeTag == tag ? universalAccentColor : .white)
						.matchedGeometryEffect(id: "ACTIVETAG_\(tag.displayName)", in: animation)
				}
		}
		.buttonStyle(.plain)
	}
}
