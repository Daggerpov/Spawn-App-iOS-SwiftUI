//
//  ChatroomView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/20/25.
//
import SwiftUI

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
    
    var body: some View {
        ZStack {
            // Background overlay
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.60))
                .ignoresSafeArea()
            
            // Main chatroom container
            ZStack {
                // Top handle indicator
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 50, height: 4)
                    .background(Color(red: 1, green: 1, blue: 1).opacity(0.60))
                    .cornerRadius(100)
                    .offset(x: 0, y: -280)
                
                // Messages area
                VStack(alignment: .leading, spacing: 175) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.chats, id: \.id) { message in
                            ChatMessageView(message: message, isFromCurrentUser: message.senderUser == UserAuthViewModel.shared.spawnUser)
                        }
                    }
                    
                    // Message input area
                    HStack(alignment: .top, spacing: 8) {
                        // Profile image
                        Circle()
                            .foregroundColor(.clear)
                            .frame(width: 36, height: 36)
                            .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                            .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4.02, y: 1.61)
                        
                        // Text field
                        HStack {
                            TextField("Send a message!", text: $messageText)
                                .font(.onestMedium(size: 16))
                                .foregroundColor(Color(red: 0.42, green: 0.51, blue: 0.98).opacity(0.60))
                        }
                        .padding(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .background(.white)
                        .cornerRadius(100)
                        .onChange(of: messageText) { _ in
                            // Clear error message when user starts typing
                            if viewModel.creationMessage != nil {
                                viewModel.creationMessage = nil
                            }
                        }
                        
                        // Send button
                        Button(action: {
                            Task {
                                let messageToSend = messageText
                                messageText = "" // Clear immediately for better UX
                                await viewModel.sendMessage(message: messageToSend)
                                
                                // If there was an error, restore the message text
                                if viewModel.creationMessage != nil {
                                    messageText = messageToSend
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.60))
                            }
                            .padding(8)
                            .frame(height: 36)
                            .background(Color(red: 0.42, green: 0.51, blue: 0.98))
                            .cornerRadius(100)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
                .frame(width: 428)
                .offset(x: 0, y: 32.50)
                
                // Back button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.60))
                }
                .offset(x: -178, y: -241)
                
                // Title
                Text("Chatroom")
                    .font(Font.custom("Onest", size: 20).weight(.semibold))
                    .lineSpacing(24)
                    .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.60))
                    .offset(x: 0, y: -241)
                
                // Bottom handle
                VStack(alignment: .leading, spacing: 10) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 134, height: 5)
                        .background(Color(red: 0.86, green: 0.84, blue: 0.84))
                        .cornerRadius(100)
                }
                .padding(EdgeInsets(top: 8, leading: 147, bottom: 8, trailing: 147))
                .frame(width: 428)
                .offset(x: 0, y: 283.50)
                
                // Error message display
                if let errorMessage = viewModel.creationMessage {
                    Text(errorMessage)
                        .font(.onestMedium(size: 14))
                        .foregroundColor(Color(hex: colorsRed500))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .offset(x: 0, y: 200)
                }
            }
            .frame(width: 428, height: 588)
            .background(Color(red: 0.33, green: 0.42, blue: 0.93).opacity(0.80))
            .cornerRadius(20)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                await viewModel.refreshChat()
            }
        }
    }
}

struct ChatRoomView_Previews: PreviewProvider {
    static var previews: some View {
        ChatroomView(activity: .mockSelfOwnedActivity, backgroundColor: figmaSoftBlue.opacity(0.90))
    }
}
