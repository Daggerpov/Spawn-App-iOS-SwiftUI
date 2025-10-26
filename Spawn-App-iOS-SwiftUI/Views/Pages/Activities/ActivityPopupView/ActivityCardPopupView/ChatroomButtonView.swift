//
//  ChatroomButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/18/25.
//
import SwiftUI

struct ChatroomButtonView: View {
	var user: BaseUserDTO =
		UserAuthViewModel.shared.spawnUser ?? BaseUserDTO.danielAgapov
	let activityColor: Color
	@ObservedObject var activity: FullFeedActivityDTO
	@ObservedObject var viewModel: ChatViewModel
	@State private var isLoading: Bool = true

	init(activity: FullFeedActivityDTO, activityColor: Color) {
		self.activity = activity
		self.activityColor = activityColor
		let currentUser =
			UserAuthViewModel.shared.spawnUser ?? BaseUserDTO.danielAgapov
		viewModel = ChatViewModel(
			senderUserId: currentUser.id,
			activity: activity
		)
	}

	var body: some View {
		Button(action: {
			guard !isLoading else { return }
			openChatroom()
		}) {
			HStack {
				if isLoading {
					ProgressView()
						.scaleEffect(0.8)
						.frame(width: 40, height: 40)
				} else if viewModel.chats.isEmpty {
					Image("EmptyDottedCircle")
				} else {
					profilePictures
				}

				VStack(alignment: .leading, spacing: 2) {
					Text("Chatroom")
						.foregroundColor(.white)
						.font(.onestMedium(size: 18))
					if isLoading {
						Text("Loading...")
							.foregroundColor(.white.opacity(0.8))
							.font(.onestRegular(size: 15))
					} else if viewModel.chats.isEmpty {
						Text("Be the first to send a message!")
							.foregroundColor(.white.opacity(0.8))
							.font(.onestRegular(size: 15))
					} else if !viewModel.chats.isEmpty {
						let sender = viewModel.chats[0].senderUser
						let senderName =
							sender == user
							? "You:"
							: (sender.name ?? sender.username ?? "User")
						let messageText =
							senderName + " " + viewModel.chats[0].content
						Text(messageText)
							.foregroundColor(.white.opacity(0.8))
							.font(.onestRegular(size: 15))
					}
				}
				Spacer()
			}
			.padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 20))
			.background(Color.black.opacity(0.2))
			.cornerRadius(12)
		}
		.buttonStyle(PlainButtonStyle())
		.allowsHitTesting(true)
		.contentShape(Rectangle())
		.task {
			// Use .task instead of .onAppear for better async handling
			await refreshChatAsync()
		}
	}

	// Optimized async refresh method
	private func refreshChatAsync() async {
		await viewModel.refreshChat()
		await MainActor.run {
			isLoading = false
		}
	}

	// Direct action method to avoid notification delays
	private func openChatroom() {
		NotificationCenter.default.post(name: .showChatroom, object: nil)
	}

	var profilePictures: some View {
		HStack {
			let uniqueSenders = getUniqueChatSenders()

			ForEach(Array(uniqueSenders.prefix(2).enumerated()), id: \.offset) {
				index,
				sender in
				Group {
					if let pfpUrl = sender.profilePicture {
						if MockAPIService.isMocking {
							Image(pfpUrl)
								.resizable()
								.aspectRatio(contentMode: .fill)
								.frame(
									width: index == 0 ? 40 : 30,
									height: index == 0 ? 40 : 30
								)
								.clipShape(Circle())
						} else {
							CachedProfileImage(
								userId: sender.id,
								url: URL(string: pfpUrl),
								imageType: .chatMessage
							)
							.frame(
								width: index == 0 ? 40 : 30,
								height: index == 0 ? 40 : 30
							)
						}
					} else {
						Circle()
							.fill(Color.gray.opacity(0.3))
							.frame(
								width: index == 0 ? 40 : 30,
								height: index == 0 ? 40 : 30
							)
							.overlay(
								Image(systemName: "person.fill")
									.foregroundColor(.white)
									.font(.system(size: index == 0 ? 16 : 12))
							)
					}
				}
				.offset(x: index == 1 ? -15 : 0)
			}
		}
	}

	// Helper function to get unique senders from chat messages
	private func getUniqueChatSenders() -> [BaseUserDTO] {
		var uniqueSenders: [BaseUserDTO] = []
		var seenUserIds: Set<UUID> = []

		// Get senders from most recent messages first
		for chat in viewModel.chats.reversed() {
			if !seenUserIds.contains(chat.senderUser.id) {
				uniqueSenders.append(chat.senderUser)
				seenUserIds.insert(chat.senderUser.id)
			}
		}

		return uniqueSenders
	}
}

