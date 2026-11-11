//
//  ChatMessageLikesBadge.swift
//  Spawn-App-iOS-SwiftUI
//

import SwiftUI

/// Heart and like count that hangs off the corner of a liked chat bubble (#144).
/// The heart is red when you're one of the people who liked it.
struct ChatMessageLikesBadge: View {
	let message: FullActivityChatMessageDTO
	@ObservedObject private var userAuth = UserAuthViewModel.shared

	private var likedByYou: Bool {
		userAuth.spawnUser.map { message.isLiked(by: $0.id) } ?? false
	}

	var body: some View {
		if message.likeCount > 0 {
			HStack(spacing: 3) {
				Image(systemName: "heart.fill")
					.font(.system(size: 10, weight: .semibold))
					.foregroundColor(likedByYou ? Color(hex: colorsRed500) : Color.gray)
				Text("\(message.likeCount)")
					.font(.onestMedium(size: 11))
					.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
			}
			.padding(.horizontal, 6)
			.padding(.vertical, 3)
			.background(Capsule().fill(Color.white))
			.shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
			.accessibilityElement(children: .ignore)
			.accessibilityLabel(message.likeCount == 1 ? "1 like" : "\(message.likeCount) likes")
		}
	}
}
