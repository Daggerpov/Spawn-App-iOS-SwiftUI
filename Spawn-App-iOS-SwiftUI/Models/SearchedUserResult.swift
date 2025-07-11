import Foundation

enum UserRelationshipType: String, Codable {
    case friend = "FRIEND"
    case recommendedFriend = "RECOMMENDED_FRIEND" 
    case incomingFriendRequest = "INCOMING_FRIEND_REQUEST"
    case outgoingFriendRequest = "OUTGOING_FRIEND_REQUEST"
}

struct SearchResultUser: Codable, Identifiable {
    let user: BaseUserDTO
    let relationshipType: UserRelationshipType
    let mutualFriendCount: Int?
    let friendRequestId: UUID?
    
    var id: UUID {
        return user.id
    }
}

struct SearchedUserResult: Codable {
    let users: [SearchResultUser]
} 