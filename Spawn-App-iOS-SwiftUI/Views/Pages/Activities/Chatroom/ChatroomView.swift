//
//  ChatroomView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/20/25.
//
import SwiftUI

struct ChatroomView: View {
    @State private var messageText = ""
    @State private var isExpanded = false
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
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
                Spacer()
                
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
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Invisible spacer for alignment
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // Messages area
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.chats, id: \.id) { message in
                                ChatMessageView(message: message, isFromCurrentUser: message.senderUser == UserAuthViewModel.shared.spawnUser)
                                    .transition(.move(edge: .bottom))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .refreshable {
                        Task {
                            await viewModel.refreshChat()
                        }
                    }
                    .frame(maxHeight: isExpanded ? 400 : 200)
                    
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
                            .foregroundColor(Color(red: 0.42, green: 0.51, blue: 0.98).opacity(0.60))
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
                            Text("􀈟")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color(red: 0.42, green: 0.51, blue: 0.98))
                                .cornerRadius(100)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    
                    // Bottom handle
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 134, height: 5)
                        .background(Color(red: 0.86, green: 0.84, blue: 0.84))
                        .cornerRadius(100)
                        .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity)
                .frame(height: isExpanded ? 600 : 400)
                .background(backgroundColor.opacity(0.80))
                .cornerRadius(20)
                .offset(y: dragOffset.height)
                .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: isExpanded)
                .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            isDragging = false
                            
                            // Determine if we should toggle the state based on drag direction and velocity
                            let dragThreshold: CGFloat = 50
                            let velocityThreshold: CGFloat = 500
                            
                            if abs(value.translation.height) > dragThreshold || abs(value.predictedEndTranslation.height) > velocityThreshold {
                                if value.translation.height < 0 {
                                    // Dragged up - expand
                                    isExpanded = true
                                } else {
                                    // Dragged down - collapse
                                    isExpanded = false
                                }
                            }
                            
                            // Reset drag offset
                            dragOffset = .zero
                        }
                )
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
