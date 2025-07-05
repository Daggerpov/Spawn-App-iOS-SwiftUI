import Foundation

class UserReportingService {
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
        let url = URL(string: APIService.baseURL + "blocked-users/block")!
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
        let url = URL(string: APIService.baseURL + "blocked-users/unblock")!
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
        let url = URL(string: APIService.baseURL + "blocked-users/\(blockerId)")!
        let parameters = ["returnOnlyIds": returnOnlyIds ? "true" : "false"]
        
        if returnOnlyIds {
            return try await apiService.fetchData(from: url, parameters: parameters)
        } else {
            let blockedUsers: [BlockedUserDTO] = try await apiService.fetchData(from: url, parameters: parameters)
            return blockedUsers.map { $0.blockedId }
        }
    }
    
    /// Check if a user is blocked
    /// - Parameters:
    ///   - blockerId: ID of the user who might be blocking
    ///   - blockedId: ID of the user who might be blocked
    /// - Returns: True if blocked, false otherwise
    func isUserBlocked(blockerId: UUID, blockedId: UUID) async throws -> Bool {
        let url = URL(string: APIService.baseURL + "blocked-users/is-blocked")!
        let parameters = [
            "blockerId": blockerId.uuidString,
            "blockedId": blockedId.uuidString
        ]
        
        return try await apiService.fetchData(from: url, parameters: parameters)
    }
    
    // MARK: - Reporting Users
    
    /// Report a user
    /// - Parameters:
    ///   - reporterId: ID of the user making the report
    ///   - reportedUserId: ID of the user being reported
    ///   - reportType: Type of report (harassment, violence, etc.)
    ///   - description: Description of the report
    func reportUser(
        reporterId: UUID,
        reportedUserId: UUID,
        reportType: ReportType,
        description: String
    ) async throws {
        let url = URL(string: APIService.baseURL + "reports")!
        let reportDTO = ReportedContentDTO(
            contentId: reportedUserId,
            contentType: .user,
            reportType: reportType,
            description: description
        )
        
        let _: EmptyResponse? = try await apiService.sendData(reportDTO, to: url, parameters: nil)
    }
    
    /// Get reports made by a user
    /// - Parameter reporterId: ID of the user whose reports to retrieve
    /// - Returns: Array of reports made by the user
    func getReportsByUser(reporterId: UUID) async throws -> [ReportedContentDTO] {
        let url = URL(string: APIService.baseURL + "reports/reporter/\(reporterId)")!
        return try await apiService.fetchData(from: url, parameters: nil)
    }
    
    /// Get reports about a user (admin only)
    /// - Parameter userId: ID of the user to get reports about
    /// - Returns: Array of reports about the user
    func getReportsAboutUser(userId: UUID) async throws -> [ReportedContentDTO] {
        let url = URL(string: APIService.baseURL + "reports/\(userId)")!
        return try await apiService.fetchData(from: url, parameters: nil)
    }
}

