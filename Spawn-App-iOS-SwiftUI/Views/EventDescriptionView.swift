//
//  EventDescriptionView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct EventDescriptionView: View {
	@State private var messageText: String = ""
	@ObservedObject var viewModel: EventDescriptionViewModel
	var color: Color

	init(
		event: FullFeedEventDTO, users: [BaseUserDTO]?, color: Color,
		userId: UUID
	) {
		self.viewModel = EventDescriptionViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService(
					userId: userId) : APIService(), event: event,
			users: users,
			senderUserId: userId
		)
		self.color = color
	}

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 20) {
				// Title and Time Information
				EventCardTopRowView(event: viewModel.event)
				
				// Username display
				HStack {
					usernamesView
					Spacer()
				}

				VStack {
					HStack {
						// Note
						if let note = viewModel.event.note {
							Text("\(note)")
								.font(.body)
								.padding(.bottom, 15)
								.foregroundColor(.white)
								.font(.body)
								.italic()
						}
					}
					.frame(maxWidth: .infinity, alignment: .leading)

					HStack(spacing: 10) {
						EventInfoView(
							event: viewModel.event, eventInfoType: .time)
						
						// Only show location if it exists
						if viewModel.event.location?.name != nil && !(viewModel.event.location?.name.isEmpty ?? true) {
							EventInfoView(
								event: viewModel.event, eventInfoType: .location)
						}
						
						Spacer()
						
						// Add participation toggle or edit button
						Circle()
							.CircularButton(
								systemName: viewModel.event.isSelfOwned == true 
									? "pencil" // Edit icon for self-owned events
									: (viewModel.isParticipating ? "checkmark" : "star.fill"),
								buttonActionCallback: {
									Task {
										if viewModel.event.isSelfOwned == true {
											// Handle edit action
											print("Edit event")
											// TODO: Implement edit functionality
										} else {
											// Toggle participation for non-owned events
											await viewModel.toggleParticipation()
										}
									}
								})
					}
					.foregroundColor(.white)
				}
				.frame(maxWidth: .infinity)  // Ensures the HStack uses the full width of its parent

				if let chatMessages = viewModel.event.chatMessages {
					Divider()
						.frame(height: 0.5)
						.background(Color.black)
						.opacity(1)
					HStack {
						Spacer()
						Text(
							"\(chatMessages.count) \(chatMessages.count == 1 ? "reply" : "replies")"
						)
						.foregroundColor(.black)
						.opacity(0.7)
						.font(.caption)
					}
					.frame(maxWidth: .infinity)
				}

				chatMessagesView
			}
			.padding(20)
			.background(color)
			.cornerRadius(universalRectangleCornerRadius)
		}
	}
	
	var usernamesView: some View {
		let participantCount = (viewModel.event.participantUsers?.count ?? 0) - 1 // Subtract 1 to exclude creator
		let invitedCount = viewModel.event.invitedUsers?.count ?? 0
		let totalCount = participantCount + invitedCount
		
		let displayText = (viewModel.event.isSelfOwned == true) 
			? "You\(totalCount > 0 ? " + \(totalCount) more" : "")"
			: "@\(viewModel.event.creatorUser.username)\(totalCount > 0 ? " + \(totalCount) more" : "")"
		
		return Text(displayText)
			.foregroundColor(.white)
			.font(.caption)
	}
}

extension EventDescriptionView {
	var chatMessagesView: some View {
        VStack(spacing: 10) {
            ScrollView(.vertical) {
                LazyVStack(spacing: 15) {
                    if let chatMessages = viewModel.event.chatMessages {
                        ForEach(chatMessages) { chatMessage in
                            ChatMessageRow(chatMessage: chatMessage)
                        }
                    }
                }
                .padding(.horizontal, 5)
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.3) // Adjust to be responsive to screen size
            .fixedSize(horizontal: false, vertical: false) // Allow vertical expansion based on content

			chatBar
        }
		.padding(.top, 10)
		.padding(.bottom, 10)
		.background(Color.black.opacity(0.05))
		.cornerRadius(20)
	}

	struct ChatMessageRow: View {
		let chatMessage: FullEventChatMessageDTO
		@StateObject private var actionViewModel: ChatMessageActionViewModel
		@State private var showActionMenu = false
		@State private var isLongPressing = false
		
		init(chatMessage: FullEventChatMessageDTO) {
			self.chatMessage = chatMessage
			let isInitiallyLiked = UserService.shared.hasLikedMessage(chatMessage)
			_actionViewModel = StateObject(wrappedValue: ChatMessageActionViewModel(
				apiService: MockAPIService.isMocking ? MockAPIService(userId: UserService.shared.currentUser?.id ?? UUID()) : APIService(),
				currentUserId: UserService.shared.currentUser?.id ?? UUID(),
				initialLikeState: isInitiallyLiked
			))
		}

		private func abbreviatedTime(from timestamp: String) -> String {
			let abbreviations: [String: String] = [
				"seconds": "s",
				"minutes": "m",
				"minute": "m",
				"hours": "h",
				"hour": "h",
				"day": "d",
				"days": "d",
				"week": "w",
				"weeks": "w",
			]
			var result = timestamp
			for (full, abbreviation) in abbreviations {
				result = result.replacingOccurrences(
					of: full, with: abbreviation)
			}
			return result
		}

		var body: some View {
			HStack {
				if let pfpUrl = chatMessage.senderUser.profilePicture {
					AsyncImage(url: URL(string: pfpUrl)) {
						image in
						image
							.ProfileImageModifier(imageType: .chatMessage)
					} placeholder: {
						Circle()
							.fill(Color.gray)
							.frame(width: 25, height: 25)
					}
				} else {
					Circle()
						.fill(Color.gray)
						.frame(width: 25, height: 25)
				}

				VStack(alignment: .leading, spacing: 2) {
					HStack {
						Image(systemName: "star.fill")
							.resizable()
							.scaledToFit()
							.frame(width: 15, height: 15)
							.foregroundColor(universalAccentColor)
						Text(chatMessage.senderUser.username)
							.foregroundColor(universalAccentColor)
							.bold()
							.font(.caption)
							.lineLimit(1)
					}
					Text(chatMessage.content)
						.foregroundColor(universalAccentColor)
						.font(.caption)
						.lineLimit(2)
						.fixedSize(horizontal: false, vertical: true)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				
				HStack {
					Text(abbreviatedTime(from: chatMessage.formattedTimestamp))
						.foregroundColor(.black)
						.font(.caption)
						.lineLimit(1)
						.frame(width: 40, alignment: .trailing)
					
					Button(action: {
						Task {
							await actionViewModel.toggleLike(for: chatMessage)
						}
					}) {
						Image(systemName: actionViewModel.isLiked ? "heart.fill" : "heart")
							.foregroundColor(actionViewModel.isLiked ? .red : .black)
							.frame(width: 20, height: 20)
					}
				}
				.frame(width: 70)
			}
			.padding(.vertical, 5)
			.padding(.horizontal, 15)
			.contentShape(Rectangle())
			.onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
				isLongPressing = pressing
				if pressing {
					// Add haptic feedback
					let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
					impactFeedback.impactOccurred()
				}
			}, perform: {
				showActionMenu = true
			})
			.popover(isPresented: $showActionMenu) {
				ChatMessageActionMenuView(viewModel: actionViewModel, chatMessage: chatMessage)
					.modifier(PopoverAdaptationModifier())
			}
			.scaleEffect(isLongPressing ? 1.05 : 1.0)
			.animation(.easeInOut(duration: 0.1), value: isLongPressing)
			.onAppear {
				Task {
					await actionViewModel.checkLikeStatus(for: chatMessage)
				}
			}
			.onChange(of: chatMessage.likedByUsers) { _ in
				let currentUserId = UserService.shared.currentUser?.id
				actionViewModel.isLiked = (chatMessage.likedByUsers?.contains { $0.id == currentUserId } ?? false)
			}
		}
	}

	var chatBar: some View {
		HStack {
			TextField("Add a comment", text: $messageText)
				.padding(10)
				.background(Color.white)
				.cornerRadius(10)
				.font(.subheadline)
				.foregroundColor(universalAccentColor)
				.lineLimit(1)

			Button(action: {
				// Store the current message text in a local constant
				let currentMessage = messageText
				
				// Only try to send if message is not empty
				if !currentMessage.isEmpty {
					Task {
						// Use the stored message text
						await viewModel.sendMessage(message: currentMessage)
						
						// Clear the text field on the main thread after sending
						await MainActor.run {
							messageText = ""
						}
					}
				}
			}) {
				Image(systemName: "paperplane.fill")
					.foregroundColor(Color.black)
					.frame(width: 24, height: 24)
			}
			.padding(.horizontal, 10)
			.disabled(messageText.isEmpty) // Disable button when text is empty
		}
		.padding(8)
		.background(Color.white)
		.cornerRadius(universalRectangleCornerRadius)
		.padding(.horizontal, 15)
		.frame(height: 44)
	}
}

#Preview {
	EventDescriptionView(
		event: FullFeedEventDTO.mockDinnerEvent,
		users: BaseUserDTO.mockUsers,
		color: universalAccentColor,
		userId: UUID()
	)
}

// Custom modifier to handle iOS version differences with popover adaptation
struct PopoverAdaptationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            // Use presentationCompactAdaptation on iOS 16.4+
            content.presentationCompactAdaptation(.popover)
        } else {
            // On iOS 16.2-16.3, just return the content without the modifier
            content
        }
    }
}
