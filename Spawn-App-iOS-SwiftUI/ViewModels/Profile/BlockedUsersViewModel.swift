import SwiftUI

@Observable
@MainActor
final class BlockedUsersViewModel {
	var blockedUsers: [BlockedUserDTO] = []
	var isLoading = false
	var errorMessage: String?

	private let reportingService: ReportingService
	private let notificationService = InAppNotificationService.shared

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
			errorMessage = notificationService.handleError(
				error, resource: .blockedUser, operation: .fetch)
			blockedUsers = []
		} catch {
			errorMessage = notificationService.handleError(
				error, resource: .blockedUser, operation: .fetch)
			blockedUsers = []
		}

		isLoading = false
	}

	func unblockUser(blockerId: UUID, blockedId: UUID) async {
		print("🔄 [BlockedUsersViewModel] unblockUser called - blockerId: \(blockerId), blockedId: \(blockedId)")

		do {
			try await reportingService.unblockUser(blockerId: blockerId, blockedId: blockedId)
			print("✅ [BlockedUsersViewModel] reportingService.unblockUser succeeded")

			// Remove the unblocked user from the list
			blockedUsers.removeAll { $0.blockedId == blockedId }
			print("✅ [BlockedUsersViewModel] Removed user from local list, remaining: \(blockedUsers.count)")

			errorMessage = nil
			notificationService.showSuccess(.userUnblocked)
		} catch let error as APIError {
			print("❌ [BlockedUsersViewModel] APIError: \(error)")
			errorMessage = notificationService.handleError(
				error, resource: .blockedUser, operation: .unblock)
		} catch {
			print("❌ [BlockedUsersViewModel] Error: \(error)")
			errorMessage = notificationService.handleError(
				error, resource: .blockedUser, operation: .unblock)
		}
	}

	func isUserBlocked(blockerId: UUID, blockedId: UUID) async -> Bool {
		do {
			return try await reportingService.isUserBlocked(blockerId: blockerId, blockedId: blockedId)
		} catch let error as APIError {
			// Don't show notification for this check - it's a background operation
			errorMessage = ErrorFormattingService.shared.formatAPIError(error)
			return false
		} catch {
			// Don't show notification for this check - it's a background operation
			errorMessage = ErrorFormattingService.shared.formatError(error)
			return false
		}
	}
}
