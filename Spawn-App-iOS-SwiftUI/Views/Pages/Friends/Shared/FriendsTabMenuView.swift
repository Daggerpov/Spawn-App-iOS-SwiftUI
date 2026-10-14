//
//  FriendsTabMenuView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2025-01-27.
//

import SwiftUI

struct FriendsTabMenuView: View {
	let user: Nameable
	@Binding var showReportDialog: Bool
	@Binding var showBlockDialog: Bool
	@Binding var showRemoveFriendConfirmation: Bool
	@Binding var showAddToActivityType: Bool
	let copyProfileURL: () -> Void
	let shareProfile: () -> Void
	let navigateToProfile: () -> Void
	@Environment(\.dismiss) private var dismiss
	@State private var isLoading: Bool = true

	var body: some View {
		SheetMenuContainer {
			if isLoading {
				loadingContent
			} else {
				FriendsTabMenuContent(
					showReportDialog: $showReportDialog,
					showBlockDialog: $showBlockDialog,
					showRemoveFriendConfirmation: $showRemoveFriendConfirmation,
					showAddToActivityType: $showAddToActivityType,
					copyProfileURL: copyProfileURL,
					shareProfile: shareProfile,
					navigateToProfile: navigateToProfile,
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
		SheetMenuLoadingPlaceholder(rowCount: 4, dismiss: dismiss)
	}
}

// Content view that contains the actual menu items
private struct FriendsTabMenuContent: View {
	@Binding var showReportDialog: Bool
	@Binding var showBlockDialog: Bool
	@Binding var showRemoveFriendConfirmation: Bool
	@Binding var showAddToActivityType: Bool
	let copyProfileURL: () -> Void
	let shareProfile: () -> Void
	let navigateToProfile: () -> Void
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
			SheetMenuRow(
				icon: "person.crop.circle",
				text: "View Profile",
				color: universalAccentColor
			) {
				dismiss()
				navigateToProfile()
			}
			.background(universalBackgroundColor)

			Divider()

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
				text: "Report",
				color: .red
			) {
				dismiss()
				showReportDialog = true
			}
			.background(universalBackgroundColor)

			Divider()

			SheetMenuRow(
				icon: "hand.raised.slash",
				text: "Block",
				color: .red
			) {
				dismiss()
				showBlockDialog = true
			}
			.background(universalBackgroundColor)

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
		.background(universalBackgroundColor)
	}

	private var cancelButton: some View {
		SheetMenuCancelRow(dismiss: dismiss)
	}
}

#Preview {
	FriendsTabMenuView(
		user: BaseUserDTO.danielAgapov,
		showReportDialog: .constant(false),
		showBlockDialog: .constant(false),
		showRemoveFriendConfirmation: .constant(false),
		showAddToActivityType: .constant(false),
		copyProfileURL: {},
		shareProfile: {},
		navigateToProfile: {}
	)
}
