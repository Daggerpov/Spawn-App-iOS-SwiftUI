//
//  ChatView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/20/25.
//

import SwiftUI

struct ChatMessageView: View {
    let message: FullActivityChatMessageDTO
    let isFromCurrentUser: Bool
    
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isFromCurrentUser {
                    HStack {
                        Text("\(message.senderUser.name ?? message.senderUser.username) • \(FormatterService.shared.atTime(at: message.timestamp))")
                            .font(.caption)
                            .foregroundColor(figmaTransparentWhite)
                            .padding(.leading, 20)
                        Spacer()
                    }
                    .padding(.leading)
                }
                
                HStack(alignment: .center) {
                    if !isFromCurrentUser {
                        // Profile image placeholder for spacing
                        ProfilePictureView(user: message.senderUser)
                    }
                    
                    VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                        if isFromCurrentUser {
                            Text("You • " + FormatterService.shared.atTime(at: message.timestamp))
                                .font(.onestRegular(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.trailing, 7)
                        }
                        Text(message.content)
                            .font(.onestMedium(size: 16))
                            .foregroundColor(isFromCurrentUser ? .white : .black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                isFromCurrentUser ?
                                Color.black.opacity(0.3) :
                                    figmaTransparentWhite
                            )
                            .cornerRadius(18)
                    }
                }
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
}
