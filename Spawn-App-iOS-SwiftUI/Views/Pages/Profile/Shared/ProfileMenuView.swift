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
	@State private var isLoading: Bool = true

	var body: some View {
		SheetMenuContainer {
			if isLoading {
				loadingContent
			} else {
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
			}
		}
		.background(universalBackgroundColor)
		.task {
			// Simulate a very brief loading state to ensure smooth animation
			try? await Task.sleep(for: .seconds(0.1))
			isLoading = false
		}

	}

	private var loadingContent: some View {
		SheetMenuLoadingPlaceholder(rowCount: 5, dismiss: dismiss)
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
		VStack(spacing: 16) {
			menuItems
				.background(universalBackgroundColor)

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
