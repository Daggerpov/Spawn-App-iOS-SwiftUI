//
//  ChatroomView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/20/25.
//
import SwiftUI

// MARK: - Embedded Chatroom Content View (for use within drawers)
struct ChatroomContentView: View {
    @State private var messageText = ""
    
    var user: BaseUserDTO = UserAuthViewModel.shared.spawnUser ?? BaseUserDTO.danielAgapov
    @ObservedObject var activity: FullFeedActivityDTO
    var backgroundColor: Color
    var isExpanded: Bool
    @StateObject var viewModel: ChatViewModel
    let onBack: () -> Void
    
    init(activity: FullFeedActivityDTO, backgroundColor: Color, isExpanded: Bool, onBack: @escaping () -> Void) {
        self.activity = activity
        self.backgroundColor = backgroundColor
        self.isExpanded = isExpanded
        self.onBack = onBack
        let userId = user.id
        self._viewModel = StateObject(wrappedValue: ChatViewModel(senderUserId: userId, activity: activity))
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
        VStack(spacing: 0) {
            headerView
            
            // Messages area that takes remaining space but leaves room for input
            messagesScrollView
            
            // Error message and input pinned to bottom
            VStack(spacing: 0) {
                errorMessageView
                messageInputView
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshChat()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            backButton
            Spacer()
            titleText
            Spacer()
            invisibleBalanceButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    private var backButton: some View {
        Button(action: {
            onBack()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var titleText: some View {
        Text("Chatroom")
            .font(Font.custom("Onest", size: 20).weight(.semibold))
            .foregroundColor(.white)
    }
    
    private var invisibleBalanceButton: some View {
        Button(action: {}) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.clear)
        }
        .disabled(true)
    }
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    // Sort messages chronologically (oldest first, like Instagram/WhatsApp)
                    ForEach(sortedMessages, id: \.id) { message in
                        let isFromCurrentUser = message.senderUser.id == user.id
                        
                        if isFromCurrentUser {
                            CurrentUserMessageView(message: message)
                        } else {
                            OtherUserMessageView(message: message)
                        }
                    }
                    
                    if viewModel.chats.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.horizontal, 24)
                .onChange(of: viewModel.chats.count) { _ in
                    // Auto-scroll to newest message when new messages arrive
                    if let lastMessage = sortedMessages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    // Scroll to newest message when view appears
                    if let lastMessage = sortedMessages.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .layoutPriority(-1) // Give lower priority so input area gets its space first
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
        HStack(spacing: 12) {
            userAvatarView
            messageTextField
            sendButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, isExpanded ? 20 : 85) // Increased to 85 to ensure content visibility when minimized
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
                .foregroundColor(.primary)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        .background(.white)
        .cornerRadius(20)
        .onChange(of: messageText) { _ in
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
                .frame(width: 24, height: 24)
                .padding(6)
        }
        .frame(width: 36, height: 36)
        .background(figmaSoftBlue)
        .cornerRadius(18)
        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
    }
}

// MARK: - Standalone Chatroom View (for sheets/full screen presentation)
struct ChatroomView: View {
    @State private var messageText = ""
    
    var user: BaseUserDTO = UserAuthViewModel.shared.spawnUser ?? BaseUserDTO.danielAgapov
    @ObservedObject var activity: FullFeedActivityDTO
    var backgroundColor: Color
    @StateObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(activity: FullFeedActivityDTO, backgroundColor: Color) {
        self.activity = activity
        self.backgroundColor = backgroundColor
        let userId = user.id
        self._viewModel = StateObject(wrappedValue: ChatViewModel(senderUserId: userId, activity: activity))
    }
    
    // Helper function to send messages for ChatroomView
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
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                
                // Main chatroom container
                VStack(spacing: 0) {
                    handleBar
                    headerView
                    
                    // Messages area that takes remaining space but leaves room for input
                    messagesScrollView
                    
                    // Error message, input, and handle pinned to bottom
                    VStack(spacing: 0) {
                        errorMessageView
                        messageInputView
                        bottomHandle
                    }
                }
                .background(backgroundColor)
                .cornerRadius(20)
                .padding(.horizontal, 20)
                .padding(.top, geometry.safeAreaInsets.top + 16) // Dynamic safe area + extra padding
                .padding(.bottom, geometry.safeAreaInsets.bottom + 16) // Dynamic safe area + extra padding
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                await viewModel.refreshChat()
            }
        }
    }
    
    // MARK: - View Components
    
    private var handleBar: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.white.opacity(0.6))
            .frame(width: 50, height: 4)
            .padding(.top, 8)
            .padding(.bottom, 12)
    }
    
    private var headerView: some View {
        HStack {
            backButton
            Spacer()
            titleText
            Spacer()
            invisibleBalanceButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    private var backButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var titleText: some View {
        Text("Chatroom")
            .font(Font.custom("Onest", size: 20).weight(.semibold))
            .foregroundColor(.white)
    }
    
    private var invisibleBalanceButton: some View {
        Button(action: {}) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.clear)
        }
        .disabled(true)
    }
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    // Sort messages chronologically (oldest first, like Instagram/WhatsApp)
                    ForEach(sortedMessages, id: \.id) { message in
                        let isFromCurrentUser = message.senderUser.id == user.id
                        
                        if isFromCurrentUser {
                            CurrentUserMessageView(message: message)
                        } else {
                            OtherUserMessageView(message: message)
                        }
                    }
                    
                    if viewModel.chats.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.horizontal, 24)
                .onChange(of: viewModel.chats.count) { _ in
                    // Auto-scroll to newest message when new messages arrive
                    if let lastMessage = sortedMessages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    // Scroll to newest message when view appears
                    if let lastMessage = sortedMessages.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .layoutPriority(-1) // Give lower priority so input area gets its space first
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
        HStack(spacing: 12) {
            userAvatarView
            messageTextField
            sendButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20) // Increased bottom padding to ensure visibility above tab bar
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
                .foregroundColor(.primary)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
        .background(.white)
        .cornerRadius(20)
        .onChange(of: messageText) { _ in
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
                .frame(width: 24, height: 24)
                .padding(6)
        }
        .frame(width: 36, height: 36)
        .background(figmaSoftBlue)
        .cornerRadius(18)
        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
    }
    
    private var bottomHandle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color(red: 0.86, green: 0.84, blue: 0.84))
            .frame(width: 134, height: 5)
            .padding(.bottom, 8)
    }
}

// MARK: - Message Views

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
            .background(Color.white.opacity(0.9))
            .cornerRadius(16)
    }
}

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
        Text(message.senderUser.name ?? message.senderUser.username ?? "User")
            .font(Font.custom("Onest", size: 12).weight(.medium))
            .foregroundColor(.white.opacity(0.8))
    }
    
    private var messageBubble: some View {
        Text(message.content)
            .font(Font.custom("Onest", size: 16).weight(.medium))
            .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            .background(Color.white.opacity(0.8))
            .cornerRadius(16)
    }
}

struct ChatRoomView_Previews: PreviewProvider {
    static var previews: some View {
        ChatroomView(activity: .mockSelfOwnedActivity, backgroundColor: figmaSoftBlue.opacity(0.90))
    }
}
