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
            // Get blocked user IDs first
            let blockedUserIds = try await reportingService.getBlockedUsers(blockerId: userId, returnOnlyIds: true)
            
            // For now, we'll create mock BlockedUserDTO objects since we only have IDs
            // In a real implementation, you'd fetch user details for each ID
            let blockedUserDTOs = blockedUserIds.map { blockedId in
                BlockedUserDTO(
                    id: UUID(),
                    blockerId: userId,
                    blockedId: blockedId,
                    blockerUsername: "", // Would be populated from API
                    blockedUsername: "User \(blockedId.uuidString.prefix(8))", // Placeholder
                    reason: "User blocked" // Would be populated from API
                )
            }
            
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