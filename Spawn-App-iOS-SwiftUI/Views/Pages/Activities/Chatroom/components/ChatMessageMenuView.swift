//
//  ChatMessageMenuView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 2025-01-27.
//

import SwiftUI

struct ChatMessageMenuView: View {
	let chatMessage: FullActivityChatMessageDTO
	@Binding var showReportDialog: Bool
	@Environment(\.dismiss) private var dismiss
	@State private var isLoading: Bool = true

	var body: some View {
		ChatMessageMenuContainer {
			if isLoading {
				loadingContent
			} else {
				ChatMessageMenuContent(
					chatMessage: chatMessage,
					showReportDialog: $showReportDialog,
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
			// Handle bar
			RoundedRectangle(cornerRadius: 2)
				.fill(Color(.systemGray4))
				.frame(width: 36, height: 4)
				.padding(.top, 8)

			// Loading content
			VStack(spacing: 12) {
				ProgressView()
					.scaleEffect(0.8)
				Text("Loading...")
					.font(.caption)
					.foregroundColor(.secondary)
			}
			.frame(height: 80)

			Spacer()
		}
		.background(universalBackgroundColor)
	}
}

private struct ChatMessageMenuContainer<Content: View>: View {
	let content: Content

	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	var body: some View {
		VStack(spacing: 0) {
			// Handle bar
			RoundedRectangle(cornerRadius: 2)
				.fill(Color(.systemGray4))
				.frame(width: 36, height: 4)
				.padding(.top, 8)
				.padding(.bottom, 16)

			content
		}
		.background(universalBackgroundColor)
		.cornerRadius(16, corners: [.topLeft, .topRight])
	}
}

private struct ChatMessageMenuContent: View {
	let chatMessage: FullActivityChatMessageDTO
	@Binding var showReportDialog: Bool
	let dismiss: DismissAction

	private var senderName: String {
		chatMessage.senderUser.name ?? chatMessage.senderUser.username ?? "User"
	}

	var body: some View {
		VStack(spacing: 0) {
			// Message preview
			messagePreview
				.padding(.bottom, 20)

			// Menu items
			menuItems
				.background(universalBackgroundColor)

			cancelButton
		}
		.background(universalBackgroundColor)
	}

	private var messagePreview: some View {
		VStack(spacing: 8) {
			HStack {
				if let pfpUrl = chatMessage.senderUser.profilePicture {
					CachedProfileImage(
						userId: chatMessage.senderUser.id,
						url: URL(string: pfpUrl),
						imageType: .chatMessage
					)
					.frame(width: 32, height: 32)
					.clipShape(Circle())
				} else {
					Circle()
						.fill(Color.gray.opacity(0.3))
						.frame(width: 32, height: 32)
						.overlay(
							Text(String(senderName.prefix(1)))
								.foregroundColor(.white)
								.font(.system(size: 14, weight: .semibold))
						)
				}

				VStack(alignment: .leading, spacing: 2) {
					Text(senderName)
						.font(.onestSemiBold(size: 14))
						.foregroundColor(universalAccentColor)

					Text(chatMessage.formattedTimestamp)
						.font(.onestRegular(size: 12))
						.foregroundColor(.secondary)
				}

				Spacer()
			}

			HStack {
				Text(chatMessage.content)
					.font(.onestRegular(size: 14))
					.foregroundColor(universalAccentColor)
					.lineLimit(3)
					.multilineTextAlignment(.leading)
				Spacer()
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
		.background(Color.black.opacity(0.05))
		.cornerRadius(12)
		.padding(.horizontal, 16)
	}

	private var menuItems: some View {
		VStack(spacing: 0) {
			menuItem(
				icon: "exclamationmark.triangle",
				text: "Report Message",
				color: .red
			) {
				dismiss()
				showReportDialog = true
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
		.padding(.top, 8)
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

struct ChatMessageMenuView_Previews: PreviewProvider {
	static var previews: some View {
		ChatMessageMenuView(
			chatMessage: FullActivityChatMessageDTO.mockChat1,
			showReportDialog: .constant(false)
		)
	}
}
