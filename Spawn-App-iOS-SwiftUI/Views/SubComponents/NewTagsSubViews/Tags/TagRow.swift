//
//  TagRow.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct TagRow: View {
	@EnvironmentObject var viewModel: TagsViewModel
	var friendTag: FullFriendTagDTO
	@State private var titleText: String

	@State private var isExpanded: Bool = false

	@State private var isEditingTitle: Bool = false
	@State private var editedTitleText: String
	@State private var editedColorHexCode: String

	@State private var showDeleteAlert: Bool = false

	var addFriendToTagButtonPressedCallback: (UUID) -> Void

	init(
		friendTag: FullFriendTagDTO,
		addFriendToTagButtonPressedCallback: @escaping (UUID) -> Void
	) {
		self.friendTag = friendTag
		self.addFriendToTagButtonPressedCallback =
			addFriendToTagButtonPressedCallback
		self._titleText = State(initialValue: friendTag.displayName)
		self._editedTitleText = State(initialValue: friendTag.displayName)
		self._editedColorHexCode = State(initialValue: friendTag.colorHexCode)
	}

	var body: some View {
		VStack {
			Button(action: {
				isExpanded = true
			}) {
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

										isEditingTitle = false
									}
								} else {
									isEditingTitle = true
								}
							}) {
								Image(
									systemName: isEditingTitle
										? "checkmark" : "pencil")
							}

                            if isEditingTitle, !friendTag.isEveryone{
								Button(action: {
									showDeleteAlert = true
								}) {
									Image(systemName: "trash")
								}

							}

						} else {
							Text(friendTag.displayName)
						}
					}
					.foregroundColor(.white)
					.font(.title)
					.fontWeight(.semibold)

					Spacer()
					TagFriendsView(
						friends: friendTag.friends, isExpanded: $isExpanded)
				}
				.padding()
				.background(
					RoundedRectangle(
						cornerRadius: universalRectangleCornerRadius
					)
					.fill(Color(hex: editedColorHexCode))
				)
			}
			if isExpanded {
				ExpandedTagView(
					currentSelectedColorHexCode: $editedColorHexCode,
					friendTag: friendTag, isEditingTag: $isEditingTitle,
					addFriendToTagButtonPressedCallback:
						addFriendToTagButtonPressedCallback)
			}
		}
		.alert("Delete Friend Tag", isPresented: $showDeleteAlert) {  // Add the alert
			Button("Yes", role: .destructive) {
				Task {
					await viewModel.deleteTag(id: friendTag.id)  // Call the delete method
				}
			}
			Button("No, I'll keep it", role: .cancel) {}
		} message: {
			Text("Are you sure you want to delete this friend tag?")
		}
	}
}

extension TagRow {
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

struct TagFriendsView: View {
	var friends: [BaseUserDTO]?
	@Binding var isExpanded: Bool

	var body: some View {
		ZStack {
			Button(action: {
				withAnimation {
					isExpanded.toggle()  // Toggle expanded state
				}
			}) {
				Image(systemName: "plus.circle")
					.font(.system(size: 24))
					.foregroundColor(.white)
					.clipShape(Circle())
			}
			.offset(x: CGFloat((friends?.count ?? 0)) * 15)  // Position the button after the last profile picture

			ForEach(
				Array((friends ?? []).enumerated().reversed()), id: \.element.id
			) {
				index, friend in
				if let pfpUrl = friend.profilePicture {
					AsyncImage(url: URL(string: pfpUrl)) { image in
						image
							.ProfileImageModifier(imageType: .eventParticipants)
					} placeholder: {
						Circle()
							.fill(Color.gray)
							.frame(width: 25, height: 25)
					}
					.offset(x: CGFloat(index) * 15)  // Adjust overlap spacing
				} else {
					Circle()
						.fill(.gray)
						.frame(width: 25, height: 25)
						.offset(x: CGFloat(index) * 15)  // Adjust overlap spacing
				}
			}

		}
		.padding(.trailing, CGFloat((friends?.count ?? 0) * 15))
	}
}

#Preview {
	TagRow(friendTag: FullFriendTagDTO.close, addFriendToTagButtonPressedCallback: {_ in})
}
