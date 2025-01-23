//
//  TagRow.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct TagRow: View {
	@EnvironmentObject var viewModel: TagsViewModel
	var friendTag: FriendTag
	@State private var titleText: String

	@State private var isExpanded: Bool = false

	@State private var isEditingTitle: Bool = false
	@State private var editedTitleText: String
	@State private var editedColorHexCode: String

	init(friendTag: FriendTag) {
		self.friendTag = friendTag
		self._titleText = State(initialValue: friendTag.displayName)
		self._editedTitleText = State(initialValue: friendTag.displayName)
		self._editedColorHexCode = State(initialValue: friendTag.colorHexCode)
	}

	var body: some View {
		VStack {
			HStack {
				HStack {
					if isExpanded {
						titleView

						Button(action: {
							if isEditingTitle {
								// this means they're submitting the new title/color
								Task {
									// Attempt to update the tag
									await viewModel.upsertTag(
										id: friendTag.id,
										displayName: editedTitleText,
										colorHexCode: editedColorHexCode,
										upsertAction: .update
									)

									// If successful, reset editing state
									if !viewModel.creationMessage.isEmpty {
										isEditingTitle = false
									}
								}
							} else {
								isEditingTitle = true
							}
						}) {
							Image(
								systemName: isEditingTitle
								? "checkmark" : "pencil")
						}
					} else {
						Text(friendTag.displayName)
					}
				}
				.foregroundColor(.white)
				.font(.title)
				.fontWeight(.semibold)

				Spacer()
				tagFriendsView
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
					.fill(Color(hex: editedColorHexCode))
			)
			if isExpanded {
				ExpandedTagView(currentSelectedColorHexCode: $editedColorHexCode,friendTag: friendTag)
			}
		}

	}
}

extension TagRow {
	var tagFriendsView: some View {
		HStack(spacing: -10) {
			ForEach(0..<2) { _ in
				Circle()
					.frame(width: 30, height: 30)
					.foregroundColor(.gray.opacity(0.2))
			}
			Button(action: {
				withAnimation {
					isExpanded.toggle()  // Toggle expanded state

				}
			}) {
				Image(systemName: "plus.circle")
					.font(.system(size: 24))
					.foregroundColor(universalAccentColor)
			}
		}
	}

	var titleView: some View {
		Group {
			if isEditingTitle {
				TextField(
					friendTag.displayName,
					text: $editedTitleText
				)
				.underline()
			} else {
				Text(friendTag.displayName)
					.underline()
			}
		}
	}
}
