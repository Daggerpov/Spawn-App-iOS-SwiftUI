import SwiftUI

struct CurrentUserMessageView: View {
	let message: FullActivityChatMessageDTO

	var body: some View {
		HStack {
			Spacer()
			messageBubble
		}
		.padding(.leading, 80)
	}

	private var messageBubble: some View {
		Text(message.content)
			.font(Font.custom("Onest", size: 16).weight(.medium))
			.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
			.padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
			.background(Color.white.opacity(0.6))  // Figma: rgba(255,255,255,0.6)
			.cornerRadius(12)
			.overlay(alignment: .bottomTrailing) {
				ChatMessageLikesBadge(message: message)
					.offset(x: 6, y: 12)
			}
			// Leave room for the badge hanging below the bubble
			.padding(.bottom, message.likeCount > 0 ? 8 : 0)
	}
}
