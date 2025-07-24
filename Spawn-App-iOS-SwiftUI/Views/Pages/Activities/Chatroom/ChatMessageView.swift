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
    
    @State private var showMessageMenu: Bool = false
    @State private var showReportDialog: Bool = false
    @StateObject private var userAuth = UserAuthViewModel.shared
    
    var body: some View {
        Group {
            if isFromCurrentUser {
                // Current user's message (right aligned)
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(message.content)
                            .font(Font.custom("Onest", size: 16).weight(.medium))
                            .lineSpacing(19.20)
                            .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    }
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .frame(width: 251)
                    .background(Color(red: 1, green: 1, blue: 1).opacity(0.60))
                    .cornerRadius(12)
                }
            } else {
                // Other user's message (left aligned)
                VStack(alignment: .leading, spacing: 8) {
                    // User name
                    HStack(alignment: .top, spacing: 8) {
                        Ellipse()
                            .foregroundColor(.clear)
                            .frame(width: 24, height: 14)
                            .background(Color(red: 1, green: 1, blue: 1).opacity(0.80))
                            .opacity(0)
                        Text(message.senderUser.name ?? message.senderUser.username ?? "User")
                            .font(Font.custom("Onest", size: 12).weight(.medium))
                            .lineSpacing(14.40)
                            .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.80))
                    }
                    
                    // Message bubble with profile image
                    HStack(alignment: .bottom, spacing: 8) {
                        Ellipse()
                            .foregroundColor(.clear)
                            .frame(width: 24, height: 24)
                            .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                            .shadow(
                                color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 4.02, y: 1.61
                            )
                        HStack(spacing: 10) {
                            Text(message.content)
                                .font(Font.custom("Onest", size: 16).weight(.medium))
                                .lineSpacing(19.20)
                                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                        }
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(Color(red: 1, green: 1, blue: 1).opacity(0.80))
                        .cornerRadius(12)
                    }
                    .frame(width: 300)
                }
                .frame(width: 346)
                .onLongPressGesture(minimumDuration: 0.5) {
                    // Only allow reporting other users' messages
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    showMessageMenu = true
                }
            }
        }
        .sheet(isPresented: $showMessageMenu) {
            ChatMessageMenuView(
                chatMessage: message,
                showReportDialog: $showReportDialog
            )
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showReportDialog) {
            ReportChatMessageDrawer(
                chatMessage: message,
                onReport: { reportType, description in
                    Task {
                        await reportChatMessage(reportType: reportType, description: description)
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func reportChatMessage(reportType: ReportType, description: String) async {
        guard let currentUserId = userAuth.spawnUser?.id else { return }
        
        do {
            let reportingService = ReportingService()
            try await reportingService.reportChatMessage(
                reporterUserId: currentUserId,
                chatMessageId: message.id,
                reportType: reportType,
                description: description
            )
            print("Chat message reported successfully")
        } catch {
            print("Error reporting chat message: \(error)")
        }
    }
}
