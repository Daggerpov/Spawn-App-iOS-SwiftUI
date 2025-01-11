//
//  EventDescriptionView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct EventDescriptionView: View {
    @ObservedObject var viewModel: EventDescriptionViewModel
    var color: Color
    
    init(event: Event, users: [User], color: Color) {
        self.viewModel = EventDescriptionViewModel(event: event, users: users)
        self.color = color
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and Time Information
                EventCardTopRowView(event: viewModel.event)
                
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        EventInfoView(event: viewModel.event, eventInfoType: .time)
                        EventInfoView(event: viewModel.event, eventInfoType: .location)
                    }
                    .foregroundColor(.white)
                    
                    Spacer() // Ensures alignment but doesn't add spacing below the content
                }
                
                // Note
                if let note = viewModel.event.note {
                    Text("Note: \(note)")
                        .font(.body)
                }
                
                if let chatMessages = viewModel.event.chatMessages {
                    Text("\(chatMessages.count) replies")
                }
                
                chatMessagesView
            }
            .padding(20)
            .background(color)
            .cornerRadius(universalRectangleCornerRadius)
        }
        .padding(.horizontal)
        .padding(.top, 200)
    }
}

extension EventDescriptionView {
    var chatMessagesView: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                if let chatMessages = viewModel.event.chatMessages {
                    // TODO: remove this logic out of the view, and into view model
                    ForEach(chatMessages) { chatMessage in
                        let user: User = chatMessage.userSender
                        HStack{
                            if let profilePictureString = user.profilePicture {
                                Image(profilePictureString)
                                    .ProfileImageModifier(imageType: .chatMessage)
                            }
                            VStack{
                                Text(user.username)
                                Text(chatMessage.content)
                            }
                            Spacer()
                            HStack{
								Text(ChatMessage.dateFormatter.string(from: chatMessage.timestamp))
                                // TODO: add logic later, to either use heart.fill or just heart,
                                // based on whether current user is in the chat message's likedBy array
                                Image(systemName: "heart")
                            }
                        }
                    }
                }
            }
        }
    }
}
