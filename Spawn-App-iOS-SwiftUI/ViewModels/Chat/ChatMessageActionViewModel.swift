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
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            if isLiked {
                try await apiService.unlikeChatMessage(chatMessageId: chatMessage.id, userId: currentUserId)
            } else {
                _ = try await apiService.likeChatMessage(chatMessageId: chatMessage.id, userId: currentUserId)
            }
            
            await MainActor.run {
                isLiked.toggle()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to \(isLiked ? "unlike" : "like") message: \(error.localizedDescription)"
                isLoading = false
            }
            print("Error toggling like: \(error)")
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
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
            print("Error checking like status: \(error)")
        }
    }
} 