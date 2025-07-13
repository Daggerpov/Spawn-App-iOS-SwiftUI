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
            
            VStack(spacing: 0) {
                // Small spacer to account for safe area
                Spacer()
                    .frame(height: 60)
                
                // Main chatroom container
                VStack(spacing: 0) {
                    // Top handle indicator
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 50, height: 4)
                        .background(Color.white.opacity(0.60))
                        .cornerRadius(100)
                        .padding(.top, 8)
                    
                    // Header
                    HStack {
                        ActivityBackButton {
                            dismiss()
                        }
                        
                        Spacer()
                        
                        Text("Chatroom")
                            .font(.onestSemiBold(size: 20))
                            .foregroundColor(Color.white.opacity(0.60))
                        
                        Spacer()
                        
                        // Invisible spacer for alignment
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                        
                        // Messages area
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.chats, id: \.id) { message in
                                    ChatMessageView(message: message, isFromCurrentUser: message.senderUser == UserAuthViewModel.shared.spawnUser)
                                        .transition(.move(edge: .bottom))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 32)
                        }
                        .refreshable {
                            Task {
                                await viewModel.refreshChat()
                            }
                        }
                        
                        Spacer()
                        
                        // Error message display
                        if let errorMessage = viewModel.creationMessage {
                            Text(errorMessage)
                                .font(.onestMedium(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 8)
                        }
                        
                        // Message input area
                        HStack(alignment: .top, spacing: 8) {
                            // Profile image
                            ProfilePictureView(user: user)
                            
                            // Text field
                            TextField("Send a message!", text: $messageText)
                                .font(.onestMedium(size: 16))
                                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
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
                                    await viewModel.sendMessage(message: messageToSend)
                                    
                                    // Only clear the text field if there's no error message
                                    if viewModel.creationMessage == nil {
                                        messageText = ""
                                    }
                                }
                            }) {
                                Image("chat_message_send_button")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 32, height: 32)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.33, green: 0.42, blue: 0.93).opacity(0.80))
                    .cornerRadius(20)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct ChatRoomView_Previews: PreviewProvider {
    static var previews: some View {
        ChatroomView(activity: .mockSelfOwnedActivity, backgroundColor: figmaSoftBlue.opacity(0.90))
    }
}
