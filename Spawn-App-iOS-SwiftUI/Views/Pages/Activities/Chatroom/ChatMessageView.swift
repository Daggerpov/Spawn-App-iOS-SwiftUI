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
        if isFromCurrentUser {
            // Current user's message (right aligned)
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Spacer()
                    Text(message.content)
                        .font(.onestMedium(size: 16))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .frame(maxWidth: 251)
                        .background(Color.white.opacity(0.60))
                        .cornerRadius(12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        } else {
            // Other user's message (left aligned)
            VStack(alignment: .leading, spacing: 8) {
                // User name
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .foregroundColor(.clear)
                        .frame(width: 24, height: 14)
                        .background(Color.white.opacity(0.80))
                        .opacity(0)
                    
                    Text(message.senderUser.name ?? message.senderUser.username)
                        .font(.onestMedium(size: 12))
                        .foregroundColor(Color.white.opacity(0.80))
                    
                    Spacer()
                }
                
                // Message bubble with profile image
                HStack(alignment: .bottom, spacing: 8) {
                    Circle()
                        .foregroundColor(.clear)
                        .frame(width: 24, height: 24)
                        .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                        .shadow(color: Color.black.opacity(0.25), radius: 4.02, y: 1.61)
                    
                    HStack {
                        Text(message.content)
                            .font(.onestMedium(size: 16))
                            .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .background(Color.white.opacity(0.80))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .frame(maxWidth: 300)
            }
            .frame(maxWidth: 346, alignment: .leading)
        }
    }
}
