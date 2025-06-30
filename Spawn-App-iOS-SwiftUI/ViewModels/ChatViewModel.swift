//
//  ChatViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/20/25.
//

import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    private let apiService: IAPIService
    private let senderUserId: UUID
    @ObservedObject private var activity: FullFeedActivityDTO
    
    var chats: [FullActivityChatMessageDTO] {
        activity.chatMessages ?? []
    }
    var creationMessage: String?
    
    init(senderUserId: UUID, activity: FullFeedActivityDTO) {
        self.senderUserId = senderUserId
        self.activity = activity
        apiService = MockAPIService.isMocking ? MockAPIService(userId: senderUserId) : APIService()
    }
    
    
    func sendMessage(message: String) async {
        // Validate the message is not empty
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Cannot send empty message")
            await MainActor.run {
                creationMessage = "Cannot send an empty message"
            }
            return
        }
        
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let chatMessage: CreateChatMessageDTO = CreateChatMessageDTO(
            content: trimmedMessage,
            senderUserId: senderUserId,
            activityId: activity.id
        )
        
        if let url = URL(string: APIService.baseURL + "chatMessages") {
            do {
                let response: FullActivityChatMessageDTO? = try await self.apiService.sendData(chatMessage, to: url, parameters: nil)
                
                // After successfully sending the message, fetch the updated activity data
                guard let newChatMessage = response else {
                    print("Error: No chat received from API after creating chat message")
                    creationMessage = "Error sending message"
                    return
                }
                
                await MainActor.run {
                    if activity.chatMessages == nil {
                        activity.chatMessages = []
                    }
                    activity.chatMessages?.append(newChatMessage)
                    creationMessage = nil
                }
            } catch {
                print("Error sending message: \(error)")
                await MainActor.run {
                    creationMessage = "There was an error sending your chat message. Please try again"
                }
            }
        }
    }
    
    func refreshChat() async {
        if let url = URL(string: APIService.baseURL + "activities/" + activity.id.uuidString + "/chats") {
            do {
                let chats: [FullActivityChatMessageDTO] = try await self.apiService.fetchData(from: url, parameters: nil)
                await MainActor.run {
                    activity.chatMessages = chats
                }
              
            } catch {
                print("Error refreshing chats: \(error)")
                await MainActor.run {
                    creationMessage = "There was an error refreshing the chatroom. Please try again"
                }
            }
        }
    }
}
