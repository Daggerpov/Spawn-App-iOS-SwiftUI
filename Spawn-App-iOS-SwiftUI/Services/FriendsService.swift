import Foundation

/// Service for managing friend-related operations
class FriendsService {
    private let apiService: IAPIService
    
    init(apiService: IAPIService = APIService()) {
        self.apiService = apiService
    }
    
    /// Removes a friendship between two users
    /// - Parameters:
    ///   - currentUserId: The ID of the current user
    ///   - friendUserId: The ID of the friend to remove
    /// - Throws: API errors if the request fails
    func removeFriend(currentUserId: UUID, friendUserId: UUID) async throws {
        guard let url = URL(string: APIService.baseURL + "api/v1/users/friends/\(currentUserId)/\(friendUserId)") else {
            throw APIError.URLError
        }
        
        // Use DELETE request to remove friendship
        _ = try await apiService.deleteData(
            from: url,
            parameters: nil,
            object: Optional<String>.none
        )
    }
}

