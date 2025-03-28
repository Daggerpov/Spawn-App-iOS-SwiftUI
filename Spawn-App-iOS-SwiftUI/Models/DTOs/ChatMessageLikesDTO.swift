import Foundation

struct ChatMessageLikesDTO: Codable {
    var chatMessageId: UUID
    var userId: UUID
    var timestamp: Date?
    
    init(chatMessageId: UUID, userId: UUID) {
        self.chatMessageId = chatMessageId
        self.userId = userId
    }
} 