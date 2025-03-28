import Foundation
import SwiftUI

class ChatMessageActionViewModel: ObservableObject {
    private let apiService: IAPIService
    private let currentUserId: UUID
    
    @Published var isLiked: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init(apiService: IAPIService, currentUserId: UUID, initialLikeState: Bool = false) {
        self.apiService = apiService
        self.currentUserId = currentUserId
        self.isLiked = initialLikeState
    }
    
    // MARK: - Like Message
    
    func toggleLike(for chatMessage: FullEventChatMessageDTO) async {
        guard !isLoading else { return }
        
        // Capture current state before changing
        let wasLiked = isLiked
        
        // Optimistic UI update - update the UI immediately
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            isLiked.toggle()
            
            // Optimistically update the likedByUsers array locally
            if isLiked {
                // Add current user to likes if not already present
                if let currentUser = UserService.shared.currentUser {
                    if chatMessage.likedByUsers == nil {
                        chatMessage.likedByUsers = [currentUser]
                    } else if !chatMessage.likedByUsers!.contains(where: { $0.id == currentUserId }) {
                        chatMessage.likedByUsers?.append(currentUser)
                    }
                }
            } else {
                // Remove current user from likes
                if chatMessage.likedByUsers != nil {
                    chatMessage.likedByUsers?.removeAll { $0.id == currentUserId }
                }
            }
        }
        
        do {
            // Make API call based on the NEW state (after toggle)
            if isLiked {
                try await apiService.likeChatMessage(chatMessageId: chatMessage.id, userId: currentUserId)
            } else {
                try await apiService.unlikeChatMessage(chatMessageId: chatMessage.id, userId: currentUserId)
            }
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            print("Error toggling like: \(error)")
            
            // Don't revert the UI on 500 errors - maintain optimistic update
            // Only log the error but keep the UI in sync with what the user did
            await MainActor.run {
                isLoading = false
                
                // Only show error message in debug, not to the user
                #if DEBUG
                errorMessage = "API error. Local change preserved."
                #endif
            }
        }
    }
    
    // MARK: - Report Message
    
    func reportMessage(chatMessage: FullEventChatMessageDTO, reportType: ReportType) async {
        guard !isLoading else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let report = ReportedContentDTO(
                reportType: reportType,
                contentType: .ChatMessage,
                contentId: chatMessage.id,
                contentOwnerId: chatMessage.senderUser.id,
                reporterId: currentUserId
            )
            
            _ = try await apiService.reportContent(report)
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to report message: \(error.localizedDescription)"
                isLoading = false
            }
            print("Error reporting message: \(error)")
        }
    }
    
    // MARK: - Check Like Status
    
    func checkLikeStatus(for chatMessage: FullEventChatMessageDTO) async {
        guard !isLoading else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let likes = try await apiService.getChatMessageLikes(chatMessageId: chatMessage.id)
            let userLiked = likes.contains { $0.id == currentUserId }
            
            await MainActor.run {
                isLiked = userLiked
                
                // Update the likedByUsers array to match the backend data
                // This ensures consistency between what's shown in the UI and what's in the data model
                chatMessage.likedByUsers = likes
                
                isLoading = false
            }
        } catch {
            // On error, use local state based on hasLikedMessage
            await MainActor.run {
                // Fall back to the local state - trust what UserService says
                isLiked = UserService.shared.hasLikedMessage(chatMessage)
                isLoading = false
            }
            print("Error checking like status: \(error)")
        }
    }
} 