//
//  ExpandedTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct ExpandedTagView: View {
	@Binding var currentSelectedColorHexCode: String
	var friendTag: FriendTag

	var body: some View {
		VStack(spacing: 15) {
			HStack {
				Spacer()
			}

			ColorOptions(
				currentSelectedColorHexCode: $currentSelectedColorHexCode)
			FriendContainer(friendTag: friendTag)
		}
		.padding(.horizontal)
		.padding(.bottom)
	}
}
