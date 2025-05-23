//
//  EventCardPopupDescriptionView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/20/25.
//

import SwiftUI

struct EventCardPopupDescriptionView: View {
    var event: FullFeedEventDTO
    let chatPreviewCount = 2
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let profilePictureUrl = event.creatorUser.profilePicture {
                    if MockAPIService.isMocking {
                        Image(profilePictureUrl)
                            .ProfileImageModifier(imageType: .eventParticipants)
                    } else {
                        AsyncImage(url: URL(string: profilePictureUrl)) { image in
                            image.ProfileImageModifier(imageType: .eventParticipants)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 28, height: 28)
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 28, height: 28)
                }
                Text("@" + event.creatorUser.username)
                    .font(.onestMedium(size: 13))
                    .foregroundColor(.white)
            }
            if let eventNote = event.note {
                Text(eventNote)
                    .font(.onestRegular(size: 14))
                    .foregroundColor(.white.opacity(0.95))
            }
            let chatMessages = event.chatMessages ?? []
            
            if !chatMessages.isEmpty {
                Button(action: {/* View all comments */}) {
                    Text("View all comments")
                        .font(.onestRegular(size: 13))
                        .foregroundColor(.white)
                }
                VStack {
                    ForEach(0..<min(chatMessages.count, chatPreviewCount), id: \.self) { chatIndex in
                        let chat = chatMessages[chatIndex]
                        EventPopupChatMessage(chatMessage: chat)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.13))
        .cornerRadius(14)
        .padding(.horizontal)
        .padding(.bottom, 14)
    }
}

struct EventPopupChatMessage: View {
    var senderProfilePictureUrl: String?
    var senderUsername: String
    var message: String
    
    init(chatMessage: FullEventChatMessageDTO) {
        senderProfilePictureUrl = chatMessage.senderUser.profilePicture
        senderUsername = chatMessage.senderUser.username
        message = chatMessage.content
    }
    
    var body: some View {
        Text("@" + senderUsername)
            .font(.onestSemiBold(size: 13))
            .foregroundColor(.white)
        + Text(" " + message)
            .font(.onestRegular(size: 13))
            .foregroundColor(.white)
    }
}
