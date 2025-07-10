import Foundation
import SwiftUI

@MainActor
class BlockedUsersViewModel: ObservableObject {
    @Published var blockedUsers: [BlockedUserDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let reportingService: UserReportingService
    
    init(reportingService: UserReportingService = UserReportingService()) {
        self.reportingService = reportingService
    }
    
    func loadBlockedUsers(for userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get full blocked user details instead of just IDs
            let blockedUserDTOs: [BlockedUserDTO] = try await reportingService.getFullBlockedUsers(blockerId: userId)
            blockedUsers = blockedUserDTOs
        } catch {
            errorMessage = "Failed to load blocked users: \(error.localizedDescription)"
            blockedUsers = []
        }
        
        isLoading = false
    }
    
    func unblockUser(blockerId: UUID, blockedId: UUID) async {
        do {
            try await reportingService.unblockUser(blockerId: blockerId, blockedId: blockedId)
            
            // Remove the unblocked user from the list
            blockedUsers.removeAll { $0.blockedId == blockedId }
            
            errorMessage = nil
        } catch {
            errorMessage = "Failed to unblock user: \(error.localizedDescription)"
        }
    }
    
    func isUserBlocked(blockerId: UUID, blockedId: UUID) async -> Bool {
        do {
            return try await reportingService.isUserBlocked(blockerId: blockerId, blockedId: blockedId)
        } catch {
            errorMessage = "Failed to check block status: \(error.localizedDescription)"
            return false
        }
    }
} 