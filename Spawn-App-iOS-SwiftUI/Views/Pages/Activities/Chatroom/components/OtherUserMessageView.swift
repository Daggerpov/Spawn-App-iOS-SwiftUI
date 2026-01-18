import SwiftUI

struct OtherUserMessageView: View {
	let message: FullActivityChatMessageDTO

	var body: some View {
		HStack(alignment: .bottom, spacing: 8) {
			userAvatar
			messageContent
			Spacer()
		}
		.padding(.trailing, 80)
	}

	private var userAvatar: some View {
		Circle()
			.fill(Color.white.opacity(0.3))
			.frame(width: 24, height: 24)
			.overlay(
				Text(userInitial)
					.font(.system(size: 10, weight: .semibold))
					.foregroundColor(.white)
			)
	}

	private var userInitial: String {
		String(message.senderUser.name?.first ?? message.senderUser.username?.first ?? "?").uppercased()
	}

	private var messageContent: some View {
		VStack(alignment: .leading, spacing: 4) {
			userNameText
			messageBubble
		}
	}

	private var userNameText: some View {
		HStack(spacing: 6) {
			Text(message.senderUser.name ?? message.senderUser.username ?? "User")
				.font(Font.custom("Onest", size: 12).weight(.medium))
				.foregroundColor(.white.opacity(0.8))
			Text("•")
				.font(Font.custom("Onest", size: 12).weight(.medium))
				.foregroundColor(.white.opacity(0.7))
			Text(FormatterService.shared.chatTimestamp(from: message.timestamp))
				.font(Font.custom("Onest", size: 12).weight(.medium))
				.foregroundColor(.white.opacity(0.7))
		}
	}

	private var messageBubble: some View {
		Text(message.content)
			.font(Font.custom("Onest", size: 16).weight(.medium))
			.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
			.padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
			.background(Color.white.opacity(0.8))  // Figma: rgba(255,255,255,0.8)
			.cornerRadius(12)
	}
}
