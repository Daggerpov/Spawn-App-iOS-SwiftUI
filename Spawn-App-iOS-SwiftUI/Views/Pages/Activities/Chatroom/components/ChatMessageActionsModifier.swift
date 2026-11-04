//
//  ChatMessageActionsModifier.swift
//  Spawn-App-iOS-SwiftUI
//

import SwiftUI

/// Long-press actions for a chatroom message (#144): opens `ChatMessageMenuView`, then whatever the
/// chosen action needs (the report drawer, or a delete confirmation).
struct ChatMessageActionsModifier: ViewModifier {
	let message: FullActivityChatMessageDTO
	let isFromCurrentUser: Bool
	let onToggleLike: () -> Void
	let onDelete: () -> Void

	@State private var showMessageMenu = false
	/// Set by the menu. It's handled once the menu has finished dismissing, so two sheets or a
	/// sheet and an alert never try to present at the same time.
	@State private var pendingAction: ChatMessageMenuAction?
	@State private var showReportDialog = false
	@State private var showDeleteConfirmation = false
	@ObservedObject private var userAuth = UserAuthViewModel.shared

	private var actions: [ChatMessageMenuAction] {
		// You can delete your own messages, and like or report everyone else's
		if isFromCurrentUser {
			return [.delete]
		}
		let isLiked = userAuth.spawnUser.map { message.isLiked(by: $0.id) } ?? false
		return [.like(isLiked: isLiked), .report]
	}

	func body(content: Content) -> some View {
		content
			.contentShape(Rectangle())
			.onLongPressGesture(minimumDuration: 0.5) {
				UIImpactFeedbackGenerator(style: .medium).impactOccurred()
				showMessageMenu = true
			}
			.sheet(isPresented: $showMessageMenu, onDismiss: handlePendingAction) {
				ChatMessageMenuView(chatMessage: message, actions: actions) { action in
					pendingAction = action
				}
				.presentationDetents([.height(ChatMessageMenuView.sheetHeight(actionCount: actions.count))])
				.presentationDragIndicator(.visible)
			}
			.sheet(isPresented: $showReportDialog) {
				ReportChatMessageDrawer(
					chatMessage: message,
					onReport: { reportType, description in
						Task {
							await reportMessage(reportType: reportType, description: description)
						}
					}
				)
				.presentationDetents([.medium, .large])
				.presentationDragIndicator(.visible)
			}
			.alert("Delete message?", isPresented: $showDeleteConfirmation) {
				Button("Cancel", role: .cancel) {}
				Button("Delete", role: .destructive, action: onDelete)
			} message: {
				Text("It will be removed from the chat for everyone.")
			}
	}

	private func handlePendingAction() {
		guard let action = pendingAction else { return }
		pendingAction = nil

		switch action {
		case .like:
			onToggleLike()
		case .report:
			showReportDialog = true
		case .delete:
			showDeleteConfirmation = true
		}
	}

	private func reportMessage(reportType: ReportType, description: String) async {
		guard let currentUserId = userAuth.spawnUser?.id else { return }

		do {
			try await ReportingService().reportChatMessage(
				reporterUserId: currentUserId,
				chatMessageId: message.id,
				reportType: reportType,
				description: description
			)
		} catch {
			print("Error reporting chat message: \(error)")
		}
	}
}

extension View {
	/// Adds the long-press message menu to a chatroom message
	func chatMessageActions(
		for message: FullActivityChatMessageDTO,
		isFromCurrentUser: Bool,
		onToggleLike: @escaping () -> Void,
		onDelete: @escaping () -> Void
	) -> some View {
		modifier(
			ChatMessageActionsModifier(
				message: message,
				isFromCurrentUser: isFromCurrentUser,
				onToggleLike: onToggleLike,
				onDelete: onDelete
			)
		)
	}
}
