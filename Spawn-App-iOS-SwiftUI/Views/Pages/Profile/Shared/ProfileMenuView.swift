//
//  ProfileMenuView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-12.
//

import SwiftUI

struct ProfileMenuView: View {
	let user: Nameable
	@Binding var showRemoveFriendConfirmation: Bool
	@Binding var showReportDialog: Bool
	@Binding var showBlockDialog: Bool
	@Binding var showAddToActivityType: Bool
	let isFriend: Bool
	let copyProfileURL: () -> Void
	let shareProfile: () -> Void
	@Environment(\.dismiss) private var dismiss
	// Measure the rows so the sheet fits both friend and non-friend menus.
	@State private var contentHeight: CGFloat = 0

	private var initialHeight: CGFloat {
		// Six actions for friends, four for other users, plus Cancel and dividers.
		let actionCount = isFriend ? 6 : 4
		return CGFloat(actionCount + 1) * 63 + CGFloat(actionCount)
	}

	var body: some View {
		ScrollView {
			ProfileMenuContent(
				showRemoveFriendConfirmation: $showRemoveFriendConfirmation,
				showReportDialog: $showReportDialog,
				showBlockDialog: $showBlockDialog,
				showAddToActivityType: $showAddToActivityType,
				isFriend: isFriend,
				copyProfileURL: copyProfileURL,
				shareProfile: shareProfile,
				dismiss: dismiss
			)
			.background {
				GeometryReader { geometry in
					Color.clear.preference(key: ProfileMenuHeightKey.self, value: geometry.size.height)
				}
			}
		}
		.scrollBounceBehavior(.basedOnSize)
		.background(universalBackgroundColor)
		.presentationBackground(universalBackgroundColor)
		.presentationDragIndicator(.hidden)
		.presentationDetents([.height(contentHeight > 0 ? contentHeight : initialHeight)])
		.onPreferenceChange(ProfileMenuHeightKey.self) { height in
			if height > 0 {
				contentHeight = height
			}
		}
	}
}

private struct ProfileMenuHeightKey: PreferenceKey {
	static var defaultValue: CGFloat { 0 }

	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = max(value, nextValue())
	}
}

// Content view that contains the actual menu items
private struct ProfileMenuContent: View {
	@Binding var showRemoveFriendConfirmation: Bool
	@Binding var showReportDialog: Bool
	@Binding var showBlockDialog: Bool
	@Binding var showAddToActivityType: Bool
	let isFriend: Bool
	let copyProfileURL: () -> Void
	let shareProfile: () -> Void
	let dismiss: DismissAction

	var body: some View {
		VStack(spacing: 0) {
			menuItems
				.background(universalBackgroundColor)

			Divider()

			cancelButton
		}
		.background(universalBackgroundColor)
	}

	private var menuItems: some View {
		VStack(spacing: 0) {
			// Only show "Add to Activity Type" for friends
			if isFriend {
				SheetMenuRow(
					icon: "tag",
					text: "Add to Activity Type",
					color: universalAccentColor
				) {
					dismiss()
					showAddToActivityType = true
				}
				.background(universalBackgroundColor)

				Divider()
			}

			SheetMenuRow(
				icon: "link",
				text: "Copy profile URL",
				color: universalAccentColor
			) {
				copyProfileURL()
				dismiss()
			}
			.background(universalBackgroundColor)

			Divider()

			SheetMenuRow(
				icon: "square.and.arrow.up",
				text: "Share this Profile",
				color: universalAccentColor
			) {
				shareProfile()
				dismiss()
			}
			.background(universalBackgroundColor)

			Divider()

			SheetMenuRow(
				icon: "exclamationmark.triangle",
				text: "Report user",
				color: .red
			) {
				dismiss()
				showReportDialog = true
			}
			.background(universalBackgroundColor)

			Divider()

			SheetMenuRow(
				icon: "hand.raised.slash",
				text: "Block user",
				color: .red
			) {
				dismiss()
				showBlockDialog = true
			}
			.background(universalBackgroundColor)

			if isFriend {
				Divider()

				SheetMenuRow(
					icon: "person.badge.minus",
					text: "Remove Friend",
					color: .red
				) {
					dismiss()
					showRemoveFriendConfirmation = true
				}
				.background(universalBackgroundColor)
			}
		}
		.background(universalBackgroundColor)
	}

	private var cancelButton: some View {
		SheetMenuCancelRow(dismiss: dismiss)
	}
}

struct ProfileMenuView_Previews: PreviewProvider {
	static var previews: some View {
		ProfileMenuView(
			user: BaseUserDTO.danielAgapov,
			showRemoveFriendConfirmation: .constant(false),
			showReportDialog: .constant(false),
			showBlockDialog: .constant(false),
			showAddToActivityType: .constant(false),
			isFriend: true,
			copyProfileURL: {},
			shareProfile: {}
		)
	}
}
