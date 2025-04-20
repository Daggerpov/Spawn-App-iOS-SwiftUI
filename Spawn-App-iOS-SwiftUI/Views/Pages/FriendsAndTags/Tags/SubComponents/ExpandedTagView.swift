//
//  ExpandedTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct ExpandedTagView: View {
	@Binding var currentSelectedColorHexCode: String
	var friendTag: FullFriendTagDTO
	@Binding var isEditingTag: Bool
	var addFriendToTagButtonPressedCallback: (UUID) -> Void

	var body: some View {
		VStack(spacing: 15) {
			HStack {
				Spacer()
			}
			if isEditingTag {
				ColorOptions(
					currentSelectedColorHexCode: $currentSelectedColorHexCode)
			}
			FriendContainer(
				friendTag: friendTag,
				addFriendsToTagButtonPressedCallback:
					addFriendToTagButtonPressedCallback
			)
		}
		.padding(.horizontal)
		.padding(.bottom)
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	@Previewable @State var currentHex: String = universalAccentColorHexCode
	@Previewable @State var isEditing: Bool = true
	ExpandedTagView(
		currentSelectedColorHexCode: $currentHex,
		friendTag: FullFriendTagDTO.close,
		isEditingTag: $isEditing,
		addFriendToTagButtonPressedCallback: {_ in}
	).environmentObject(appCache)
}
