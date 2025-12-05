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

	private var firstName: String {
		if let name = user.name, !name.isEmpty {
			return name.components(separatedBy: " ").first ?? user.username ?? "User"
		}
		return user.username ?? "User"
	}

	var body: some View {
		FriendsTabMenuContainer {
			if isLoading {
				loadingContent
			} else {
				FriendsTabMenuContent(
					user: user,
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
		VStack(spacing: 16) {
			ForEach(0..<4) { _ in
				HStack {
					RoundedRectangle(cornerRadius: 4)
						.fill(Color.gray.opacity(0.2))
						.frame(height: 20)
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
			}

			Divider()

			Button(action: { dismiss() }) {
				Text("Cancel")
					.font(.headline)
					.foregroundColor(universalAccentColor)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 16)
			}
			.background(universalBackgroundColor)
			.cornerRadius(12)
		}
		.background(universalBackgroundColor)
		.redacted(reason: .placeholder)
		.shimmering()
	}
}

// Container view that provides the background and layout
private struct FriendsTabMenuContainer<Content: View>: View {
	let content: Content

	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	var body: some View {
		VStack(spacing: 8) {
			content
				.background(universalBackgroundColor)
				.cornerRadius(12)
		}
		.fixedSize(horizontal: false, vertical: true)
		.background(universalBackgroundColor)
	}
}

// Content view that contains the actual menu items
private struct FriendsTabMenuContent: View {
	let user: Nameable
	@Binding var showReportDialog: Bool
	@Binding var showBlockDialog: Bool
	@Binding var showRemoveFriendConfirmation: Bool
	@Binding var showAddToActivityType: Bool
	let copyProfileURL: () -> Void
	let shareProfile: () -> Void
	let navigateToProfile: () -> Void
	let dismiss: DismissAction

	private var firstName: String {
		if let name = user.name, !name.isEmpty {
			return name.components(separatedBy: " ").first ?? user.username ?? "User"
		}
		return user.username ?? "User"
	}

	var body: some View {
		VStack(spacing: 0) {
			menuItems
				.background(universalBackgroundColor)

			cancelButton
		}
		.background(universalBackgroundColor)
	}

	private var menuItems: some View {
		VStack(spacing: 0) {
			menuItem(
				icon: "person.crop.circle",
				text: "View Profile",
				color: universalAccentColor
			) {
				dismiss()
				navigateToProfile()
			}
			.background(universalBackgroundColor)

			Divider()

			menuItem(
				icon: "tag",
				text: "Add to Activity Type",
				color: universalAccentColor
			) {
				dismiss()
				showAddToActivityType = true
			}
			.background(universalBackgroundColor)

			Divider()

			menuItem(
				icon: "link",
				text: "Copy profile URL",
				color: universalAccentColor
			) {
				copyProfileURL()
				dismiss()
			}
			.background(universalBackgroundColor)

			Divider()

			menuItem(
				icon: "square.and.arrow.up",
				text: "Share this Profile",
				color: universalAccentColor
			) {
				shareProfile()
				dismiss()
			}
			.background(universalBackgroundColor)

			Divider()

			menuItem(
				icon: "exclamationmark.triangle",
				text: "Report",
				color: .red
			) {
				dismiss()
				showReportDialog = true
			}
			.background(universalBackgroundColor)

			Divider()

			menuItem(
				icon: "hand.raised.slash",
				text: "Block",
				color: .red
			) {
				dismiss()
				showBlockDialog = true
			}
			.background(universalBackgroundColor)

			Divider()

			menuItem(
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
		Button(action: { dismiss() }) {
			Text("Cancel")
				.font(.headline)
				.foregroundColor(universalAccentColor)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 16)
		}
		.background(universalBackgroundColor)
		.cornerRadius(12)
	}

	private func menuItem(
		icon: String,
		text: String,
		color: Color,
		action: @escaping () -> Void
	) -> some View {
		Button(action: action) {
			HStack {
				Image(systemName: icon)
					.foregroundColor(color)

				Text(text)
					.foregroundColor(color)

				Spacer()
			}
			.padding(.vertical, 16)
			.padding(.horizontal, 16)
		}
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
