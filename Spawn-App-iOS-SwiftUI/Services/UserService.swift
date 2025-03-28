import Foundation

class UserService {
    static let shared = UserService()
    
    // Use a private initializer to enforce singleton pattern
    private init() {}
    
    // Store current user information
    private(set) var currentUser: BaseUserDTO?
    
    // Set the current user
    func setCurrentUser(_ user: BaseUserDTO) {
        currentUser = user
    }
    
    // Clear the current user (for logout)
    func clearCurrentUser() {
        currentUser = nil
    }
    
    // Check if the current user has liked a message
    func hasLikedMessage(_ chatMessage: FullEventChatMessageDTO) -> Bool {
        guard let currentUserId = currentUser?.id else { return false }
        return chatMessage.likedByUsers?.contains { $0.id == currentUserId } ?? false
    }
    
    // Get current user ID safely
    var currentUserId: UUID? {
        return currentUser?.id
    }
} 