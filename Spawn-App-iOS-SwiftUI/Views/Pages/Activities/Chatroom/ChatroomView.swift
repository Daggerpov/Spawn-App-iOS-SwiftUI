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
    var activity: FullFeedActivityDTO
    var backgroundColor: Color
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(activity: FullFeedActivityDTO, backgroundColor: Color) {
        self.activity = activity
        self.backgroundColor = backgroundColor
        self.viewModel = ChatViewModel(senderUserId: user.id, activity: activity)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [backgroundColor], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // Navigation header
                HStack {
                    Button(action: {dismiss()}) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(figmaTransparentWhite)
                            .font(.onestMedium(size: 20))
                    }
                    
                    Spacer()
                    
                    Text("Chatroom")
                        .foregroundColor(figmaTransparentWhite)
                        .font(.onestMedium(size: 20))
                    
                    Spacer()
                    
                    // Invisible spacer to balance the back button
                    Image(systemName: "chevron.left")
                        .foregroundColor(.clear)
                        .font(.title2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Messages list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.chats, id: \.id) { message in
                            ChatMessageView(message: message, isFromCurrentUser: message.senderUser == UserAuthViewModel.shared.spawnUser)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // Message input area
                HStack(spacing: 12) {
                    // Profile image
//                    ProfilePictureView(user: user)
                    
                    // Text field
                    HStack {
                        TextField("Send a message!", text: $messageText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .font(.onestRegular(size: 16))
                    }
                    .background(universalBackgroundColor)
                    .cornerRadius(25)
                    
                    // Send button
                    Button(action: {
                        Task {
                            await viewModel.sendMessage(message: messageText)
                        }
                        messageText = ""
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                            .frame(width: 44, height: 44)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct ChatRoomView_Previews: PreviewProvider {
    static var previews: some View {
        ChatroomView(activity: .mockSelfOwnedActivity, backgroundColor: figmaSoftBlue.opacity(0.90))
    }
}
