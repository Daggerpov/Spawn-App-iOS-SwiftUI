import Foundation

struct SearchedUserResult: Codable {
    var incomingFriendRequests: [FetchFriendRequestDTO]
    var recommendedFriends: [RecommendedFriendUserDTO]
    var friends: [FullFriendUserDTO]
} 