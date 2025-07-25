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
    @Published var creationMessage: String?
    
    init(senderUserId: UUID, activity: FullFeedActivityDTO) {
        self.senderUserId = senderUserId
        self.activity = activity
        apiService = MockAPIService.isMocking ? MockAPIService(userId: senderUserId) : APIService()
    }
    
    
    func sendMessage(message: String) async {
        // Clear any previous error message
        await MainActor.run {
            creationMessage = nil
        }
        
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
                
                // After successfully sending the message, handle the response
                await MainActor.run {
                    guard let newChatMessage = response else {
                        print("Error: No chat received from API after creating chat message")
                        creationMessage = "Error sending message. Please try again."
                        return
                    }
                    
                    // Check if this message already exists to prevent duplicates
                    if let existingMessages = activity.chatMessages,
                       !existingMessages.contains(where: { $0.id == newChatMessage.id }) {
                        activity.chatMessages?.append(newChatMessage)
                    } else if activity.chatMessages == nil {
                        activity.chatMessages = [newChatMessage]
                    }
                    
                    // Clear error message on success
                    creationMessage = nil
                }
            } catch {
                print("Error sending message: \(error)")
                await MainActor.run {
                    creationMessage = "There was an error sending your chat message. Please try again."
                }
            }
        } else {
            await MainActor.run {
                creationMessage = "Invalid server configuration. Please contact support."
            }
        }
    }
    
    func refreshChat() async {
        if let url = URL(string: APIService.baseURL + "activities/" + activity.id.uuidString + "/chats") {
            do {
                let chats: [FullActivityChatMessageDTO] = try await self.apiService.fetchData(from: url, parameters: nil)
                await MainActor.run {
                    // Only update if we actually got data
                    if !chats.isEmpty || activity.chatMessages?.isEmpty == true {
                        activity.chatMessages = chats
                    }
                    // Clear any error messages on successful refresh
                    if creationMessage != nil {
                        creationMessage = nil
                    }
                }
              
            } catch {
                print("Error refreshing chats: \(error)")
                await MainActor.run {
                    // Only show refresh error if there are no existing messages
                    if activity.chatMessages?.isEmpty != false {
                        creationMessage = "Unable to load messages. Please try again."
                    }
                }
            }
        } else {
            await MainActor.run {
                creationMessage = "Invalid server configuration. Please contact support."
            }
        }
    }
}
