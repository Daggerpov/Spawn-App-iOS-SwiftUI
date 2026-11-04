//
//  ChatMessageActionsModifier.swift
//  Spawn-App-iOS-SwiftUI
//

import SwiftUI

/// Long-press actions for a chatroom message (#144): opens `ChatMessageMenuView`, and from there
/// the report drawer.
struct ChatMessageActionsModifier: ViewModifier {
	let message: FullActivityChatMessageDTO
	let isFromCurrentUser: Bool

	@State private var showMessageMenu = false
	/// Set by the menu's Report item. The report drawer opens once the menu has finished dismissing,
	/// so the two sheets never try to present at the same time.
	@State private var wantsReport = false
	@State private var showReportDialog = false
	@ObservedObject private var userAuth = UserAuthViewModel.shared

	func body(content: Content) -> some View {
		content
			.contentShape(Rectangle())
			.onLongPressGesture(minimumDuration: 0.5) {
				// Report is the only action for now, and you can't report your own message
				guard !isFromCurrentUser else { return }
				UIImpactFeedbackGenerator(style: .medium).impactOccurred()
				showMessageMenu = true
			}
			.sheet(
				isPresented: $showMessageMenu,
				onDismiss: {
					if wantsReport {
						wantsReport = false
						showReportDialog = true
					}
				}
			) {
				ChatMessageMenuView(chatMessage: message, showReportDialog: $wantsReport)
					.presentationDetents([.height(200)])
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
	/// Adds the long-press message menu (currently Report) to a chatroom message
	func chatMessageActions(for message: FullActivityChatMessageDTO, isFromCurrentUser: Bool) -> some View {
		modifier(ChatMessageActionsModifier(message: message, isFromCurrentUser: isFromCurrentUser))
	}
}
