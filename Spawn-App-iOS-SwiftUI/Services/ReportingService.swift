import Foundation

class ReportingService {
    private let apiService: IAPIService
    
    init(apiService: IAPIService = APIService()) {
        self.apiService = apiService
    }
    
    // MARK: - Blocking Users
    
    /// Block a user
    /// - Parameters:
    ///   - blockerId: ID of the user doing the blocking
    ///   - blockedId: ID of the user being blocked  
    ///   - reason: Reason for blocking
    func blockUser(blockerId: UUID, blockedId: UUID, reason: String) async throws {
        guard let url = URL(string: APIService.baseURL + "blocked-users/block") else {
            throw APIError.URLError
        }
        let blockDTO = BlockedUserCreationDTO(
            blockerId: blockerId,
            blockedId: blockedId,
            reason: reason
        )
        
        let _: EmptyResponse? = try await apiService.sendData(blockDTO, to: url, parameters: nil)
    }
    
    /// Unblock a user
    /// - Parameters:
    ///   - blockerId: ID of the user doing the unblocking
    ///   - blockedId: ID of the user being unblocked
    func unblockUser(blockerId: UUID, blockedId: UUID) async throws {
        guard let url = URL(string: APIService.baseURL + "blocked-users/unblock") else {
            throw APIError.URLError
        }
        let parameters = [
            "blockerId": blockerId.uuidString,
            "blockedId": blockedId.uuidString
        ]
        
        try await apiService.deleteData(from: url, parameters: parameters, object: Optional<String>.none)
    }
    
    /// Get list of blocked users
    /// - Parameters:
    ///   - blockerId: ID of the user whose blocked list to retrieve
    ///   - returnOnlyIds: If true, returns only UUIDs; if false, returns full BlockedUserDTO objects
    /// - Returns: Either array of UUIDs or array of BlockedUserDTO objects
    func getBlockedUsers(blockerId: UUID, returnOnlyIds: Bool = false) async throws -> [UUID] {
        guard let url = URL(string: APIService.baseURL + "blocked-users/\(blockerId)") else {
            throw APIError.URLError
        }
        let parameters = ["returnOnlyIds": returnOnlyIds ? "true" : "false"]
        
        if returnOnlyIds {
            return try await apiService.fetchData(from: url, parameters: parameters)
        } else {
            let blockedUsers: [BlockedUserDTO] = try await apiService.fetchData(from: url, parameters: parameters)
            return blockedUsers.map { $0.blockedId }
        }
    }
    
    /// Get full blocked user details
    /// - Parameter blockerId: ID of the user whose blocked list to retrieve
    /// - Returns: Array of full BlockedUserDTO objects with user details
    func getFullBlockedUsers(blockerId: UUID) async throws -> [BlockedUserDTO] {
        guard let url = URL(string: APIService.baseURL + "blocked-users/\(blockerId)") else {
            throw APIError.URLError
        }
        let parameters = ["returnOnlyIds": "false"]
        
        return try await apiService.fetchData(from: url, parameters: parameters)
    }
    
    /// Check if a user is blocked
    /// - Parameters:
    ///   - blockerId: ID of the user who might be blocking
    ///   - blockedId: ID of the user who might be blocked
    /// - Returns: True if blocked, false otherwise
    func isUserBlocked(blockerId: UUID, blockedId: UUID) async throws -> Bool {
        guard let url = URL(string: APIService.baseURL + "blocked-users/is-blocked") else {
            throw APIError.URLError
        }
        let parameters = [
            "blockerId": blockerId.uuidString,
            "blockedId": blockedId.uuidString
        ]
        
        return try await apiService.fetchData(from: url, parameters: parameters)
    }
    
    // MARK: - Reporting Users
    
    func reportUser(
        reporterUserId: UUID,
        reportedUserId: UUID,
        reportType: ReportType,
        description: String
    ) async throws {
        guard let url = URL(string: APIService.baseURL + "reports/create") else {
            throw APIError.URLError
        }
        let reportDTO = CreateReportedContentDTO(
            reporterUserId: reporterUserId,
            contentId: reportedUserId,
            contentType: .user,
            reportType: reportType,
            description: description
        )
        
        let _: EmptyResponse? = try await apiService.sendData(reportDTO, to: url, parameters: nil)
    }
    
    // MARK: - Reporting Chat Messages
    
    func reportChatMessage(
        reporterUserId: UUID,
        chatMessageId: UUID,
        reportType: ReportType,
        description: String
    ) async throws {
        guard let url = URL(string: APIService.baseURL + "reports/create") else {
            throw APIError.URLError
        }
        let reportDTO = CreateReportedContentDTO(
            reporterUserId: reporterUserId,
            contentId: chatMessageId,
            contentType: .chatMessage,
            reportType: reportType,
            description: description
        )
        
        let _: EmptyResponse? = try await apiService.sendData(reportDTO, to: url, parameters: nil)
    }
    
    // MARK: - Reporting Activities
    
    func reportActivity(
        reporterUserId: UUID,
        activityId: UUID,
        reportType: ReportType,
        description: String
    ) async throws {
        guard let url = URL(string: APIService.baseURL + "reports/create") else {
            throw APIError.URLError
        }
        let reportDTO = CreateReportedContentDTO(
            reporterUserId: reporterUserId,
            contentId: activityId,
            contentType: .activity,
            reportType: reportType,
            description: description
        )
        
        let _: EmptyResponse? = try await apiService.sendData(reportDTO, to: url, parameters: nil)
    }
    
    /// Legacy method for backward compatibility
    /// - Deprecated: Use reportUser(reporterUserId:reportedUserId:reportType:description:) instead
    @available(*, deprecated, message: "Use reportUser(reporterUserId:reportedUserId:reportType:description:) instead")
    func reportUser(
        reporter: UserDTO,
        reportedUser: UserDTO,
        reportType: ReportType,
        description: String
    ) async throws {
        try await reportUser(
            reporterUserId: reporter.id,
            reportedUserId: reportedUser.id,
            reportType: reportType,
            description: description
        )
    }
    
    /// Get reports made by a user (simplified for "my reports" page)
    /// - Parameter reporterId: ID of the user whose reports to retrieve
    /// - Returns: Array of simplified reports made by the user
    func getReportsByUser(reporterId: UUID) async throws -> [FetchReportedContentDTO] {
        guard let url = URL(string: APIService.baseURL + "reports/fetch/reporter/\(reporterId)") else {
            throw APIError.URLError
        }
        return try await apiService.fetchData(from: url, parameters: nil)
    }
    
    /// Legacy method that returns full DTOs for backward compatibility
    /// - Deprecated: Use getReportsByUser(reporterId:) instead for better performance
    @available(*, deprecated, message: "Use getReportsByUser(reporterId:) instead for better performance")
    func getFullReportsByUser(reporterId: UUID) async throws -> [ReportedContentDTO] {
        guard let url = URL(string: APIService.baseURL + "reports/reporter/\(reporterId)") else {
            throw APIError.URLError
        }
        return try await apiService.fetchData(from: url, parameters: nil)
    }
    
    /// Get reports about a user (admin only)
    /// - Parameter userId: ID of the user to get reports about
    /// - Returns: Array of reports about the user
    func getReportsAboutUser(userId: UUID) async throws -> [ReportedContentDTO] {
        guard let url = URL(string: APIService.baseURL + "reports/\(userId)") else {
            throw APIError.URLError
        }
        return try await apiService.fetchData(from: url, parameters: nil)
    }
}

