import SwiftUI

// MARK: - Embedded Chatroom Content View (for use within drawers)
struct ChatroomContentView: View {
	@State private var messageText = ""
	@StateObject private var keyboardOverlap = KeyboardOverlapHeight()

	var user: BaseUserDTO = UserAuthViewModel.shared.spawnUser ?? BaseUserDTO.danielAgapov
	@ObservedObject var activity: FullFeedActivityDTO
	var backgroundColor: Color
	var isExpanded: Bool
	var fromMapView: Bool?
	@State var viewModel: ChatViewModel
	let onBack: () -> Void

	init(
		activity: FullFeedActivityDTO, backgroundColor: Color, isExpanded: Bool, fromMapView: Bool? = nil,
		onBack: @escaping () -> Void
	) {
		self.activity = activity
		self.backgroundColor = backgroundColor
		self.isExpanded = isExpanded
		self.fromMapView = fromMapView
		self.onBack = onBack
		let userId = user.id
		self._viewModel = State(wrappedValue: ChatViewModel(senderUserId: userId, activity: activity))
	}

	// Helper function to send messages for ChatroomContentView
	private func sendMessage() {
		Task {
			let messageToSend = messageText
			messageText = ""
			await viewModel.sendMessage(message: messageToSend)

			if viewModel.creationMessage != nil {
				messageText = messageToSend
			}
		}
	}

	var body: some View {
		Group {
			if isExpanded {
				VStack(spacing: 0) {
					// Header - always visible at top. The drawer already leaves room for the
					// status bar above this view, so only match the main card's header spacing.
					headerView
						.padding(.top, 8)

					// Messages fill remaining space (flexible when keyboard overlaps)
					messagesScrollView
						.frame(maxHeight: .infinity)
						.clipped()

					// Input area - anchored at bottom, above the home indicator
					VStack(spacing: 0) {
						errorMessageView
						messageInputView
							.padding(.bottom, max(windowBottomSafeAreaInset - keyboardOverlap.value, 0))
					}
					.padding(.bottom, fromMapView ?? false ? -16 : 0)
					// No fill here: the drawer's gradient shows through, so a flat band doesn't cut across it
				}
			} else {
				// When minimized, don't use GeometryReader to avoid expanding to fill available space
				// Use fixed total height to match main card content and prevent overflow
				VStack(spacing: 0) {
					// Header - always visible at top with proper spacing from handle bar
					// Figma shows header at top-[41px] from drawer, handle bar ends at ~16px
					headerView
						.padding(.top, 20)  // Match Figma spacing

					// Messages area - fills available space within the constrained height
					messagesScrollView
						.clipped()

					// Input area - directly after messages
					VStack(spacing: 0) {
						errorMessageView
						messageInputView
					}
				}
				.padding(.bottom, 90)
				.frame(height: minimizedContentHeight)  // Fixed total height to match drawer
			}
		}
		.keyboardOverlapPadding(keyboardOverlap)
		.onAppear {
			Task {
				await viewModel.refreshChat()
			}
		}
	}

	// Fixed heights for content areas
	// Figma: Drawer is 588px total, handle bar ~16px, so content area ~572px
	// But we need to account for the drawer offset (20% of screen), so visible content is less
	// Using a fixed total height ensures consistent sizing that matches main card content
	private let minimizedContentHeight: CGFloat = 600  // Total height for chatroom when minimized

	// The drawer ignores the container safe area, so views inside it see a zero bottom inset.
	// Read the home indicator inset from the window instead.
	private var windowBottomSafeAreaInset: CGFloat {
		let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
		return windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
	}

	// MARK: - View Components

	private var headerView: some View {
		HStack {
			UnifiedBackButton(foregroundColor: .white.opacity(0.6), action: onBack)
			Spacer()
			Text("Chatroom")
				.font(Font.custom("Onest", size: 20).weight(.semibold))
				.foregroundColor(.white)
			Spacer()
			InvisibleBalanceButton()
		}
		.padding(.horizontal, 24)
		.padding(.bottom, 8)  // Reduced from 16 to fit content better
	}

	private var messagesScrollView: some View {
		ScrollViewReader { proxy in
			ScrollView {
				LazyVStack(alignment: .leading, spacing: 16) {
					// Sort messages chronologically (oldest first, like Instagram/WhatsApp)
					ForEach(sortedMessages, id: \.id) { message in
						let isFromCurrentUser = message.senderUser.id == user.id

						Group {
							if isFromCurrentUser {
								CurrentUserMessageView(message: message)
							} else {
								OtherUserMessageView(message: message)
							}
						}
						.chatMessageActions(for: message, isFromCurrentUser: isFromCurrentUser)
					}

					// Don't claim there are no messages when they failed to load
					if viewModel.chats.isEmpty && !viewModel.hasLoadError {
						emptyStateView
					}
				}
				.padding(.horizontal, 24)
				.padding(.vertical, 8)  // Minimal vertical padding
				.onChange(of: viewModel.chats.count) {
					// Auto-scroll to newest message when new messages arrive
					if let lastMessage = sortedMessages.last {
						withAnimation(.easeOut(duration: 0.3)) {
							proxy.scrollTo(lastMessage.id, anchor: .bottom)
						}
					}
				}
				.onChange(of: isExpanded) {
					// When expansion state changes, maintain scroll position to bottom
					if let lastMessage = sortedMessages.last {
						Task { @MainActor in
							try? await Task.sleep(for: .seconds(0.1))
							proxy.scrollTo(lastMessage.id, anchor: .bottom)
						}
					}
				}
				.onAppear {
					// Scroll to newest message when view appears
					if let lastMessage = sortedMessages.last {
						Task { @MainActor in
							try? await Task.sleep(for: .seconds(0.1))
							proxy.scrollTo(lastMessage.id, anchor: .bottom)
						}
					}
				}
			}
			.frame(maxWidth: .infinity)
		}
	}

	// Helper computed property to sort messages chronologically
	private var sortedMessages: [FullActivityChatMessageDTO] {
		viewModel.chats.sorted { $0.timestamp < $1.timestamp }
	}

	private var emptyStateView: some View {
		VStack(spacing: 8) {
			Text("No messages yet")
				.font(Font.custom("Onest", size: 16).weight(.medium))
				.foregroundColor(.white.opacity(0.6))
			Text("Be the first to send a message!")
				.font(Font.custom("Onest", size: 14).weight(.medium))
				.foregroundColor(.white.opacity(0.4))
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical, 40)
	}

	private var errorMessageView: some View {
		Group {
			if let errorMessage = viewModel.creationMessage {
				Text(errorMessage)
					.font(.onestMedium(size: 14))
					.foregroundColor(Color(hex: colorsRed500))
					.padding(.horizontal, 24)
					.padding(.vertical, 8)
					.background(Color.white.opacity(0.9))
					.cornerRadius(8)
					.shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
					.padding(.horizontal, 24)
					.padding(.bottom, 8)
			}
		}
	}

	private var messageInputView: some View {
		HStack(spacing: 8) {  // Figma: gap-[8px]
			userAvatarView
			messageTextField
			sendButton
		}
		.padding(.horizontal, 24)
	}

	private var userAvatarView: some View {
		Circle()
			.fill(Color.white.opacity(0.3))
			.frame(width: 36, height: 36)
			.overlay(
				Text(String(user.name?.first ?? user.username?.first ?? "?").uppercased())
					.font(.system(size: 14, weight: .semibold))
					.foregroundColor(.white)
			)
	}

	private var messageTextField: some View {
		HStack {
			TextField("Send a message!", text: $messageText)
				.font(Font.custom("Onest", size: 16).weight(.medium))
				.foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))  // Dark text on white background
				.textFieldStyle(PlainTextFieldStyle())
		}
		.padding(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
		.background(.white)
		.cornerRadius(100)  // Figma: rounded-[100px]
		.shadow(color: Color.black.opacity(0.25), radius: 2, x: 2, y: 2)  // Inner shadow effect
		.onChange(of: messageText) {
			if viewModel.creationMessage != nil {
				viewModel.creationMessage = nil
			}
		}
	}

	private var sendButton: some View {
		Button(action: {
			sendMessage()
		}) {
			Image("chat_message_send_button")
				.resizable()
				.frame(width: 16, height: 16)
				.padding(8)
		}
		.frame(width: 36, height: 36)
		.background(
			// Figma gradient: linear-gradient(218deg, rgba(107, 129, 251, 1) 24%, rgba(255, 128, 236, 1) 104%)
			LinearGradient(
				gradient: Gradient(colors: [
					Color(red: 0.42, green: 0.51, blue: 0.98),  // #6B81FB
					Color(red: 1.0, green: 0.5, blue: 0.93),  // #FF80EC
				]),
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
		)
		.cornerRadius(100)
		.shadow(color: Color.black.opacity(0.25), radius: 2, x: -2, y: -2)  // Inner shadow effect
		.disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
		.opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
	}
}

#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared
	ChatroomContentView(
		activity: FullFeedActivityDTO.mockDinnerActivity,
		backgroundColor: Color.blue,
		isExpanded: false,
		onBack: {}
	)
}
