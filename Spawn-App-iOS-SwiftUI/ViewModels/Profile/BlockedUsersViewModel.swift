import SwiftUI

@Observable
@MainActor
final class BlockedUsersViewModel {
	var blockedUsers: [BlockedUserDTO] = []
	var isLoading = false
	var errorMessage: String?

	private let reportingService: ReportingService

	init(reportingService: ReportingService = ReportingService()) {
		self.reportingService = reportingService
	}

	func loadBlockedUsers(for userId: UUID) async {
		isLoading = true
		errorMessage = nil

		do {
			// Get full blocked user details instead of just IDs
			let blockedUserDTOs: [BlockedUserDTO] = try await reportingService.getFullBlockedUsers(blockerId: userId)
			blockedUsers = blockedUserDTOs
		} catch let error as APIError {
			errorMessage = ErrorFormattingService.shared.formatAPIError(error)
			blockedUsers = []
		} catch {
			errorMessage = ErrorFormattingService.shared.formatError(error)
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
		} catch let error as APIError {
			errorMessage = ErrorFormattingService.shared.formatAPIError(error)
		} catch {
			errorMessage = ErrorFormattingService.shared.formatError(error)
		}
	}

	func isUserBlocked(blockerId: UUID, blockedId: UUID) async -> Bool {
		do {
			return try await reportingService.isUserBlocked(blockerId: blockerId, blockedId: blockedId)
		} catch let error as APIError {
			errorMessage = ErrorFormattingService.shared.formatAPIError(error)
			return false
		} catch {
			errorMessage = ErrorFormattingService.shared.formatError(error)
			return false
		}
	}
}
