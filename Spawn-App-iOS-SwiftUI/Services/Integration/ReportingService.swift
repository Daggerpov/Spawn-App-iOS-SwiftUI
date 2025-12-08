import Foundation

@MainActor
final class ReportingService {
	private let dataService: DataService

	init(dataService: DataService? = nil) {
		self.dataService = dataService ?? DataService.shared
	}

	// MARK: - Blocking Users

	/// Block a user
	/// - Parameters:
	///   - blockerId: ID of the user doing the blocking
	///   - blockedId: ID of the user being blocked
	///   - reason: Reason for blocking
	func blockUser(blockerId: UUID, blockedId: UUID, reason: String) async throws {
		print("🚫 DEBUG: Starting blockUser request")
		print("🚫 DEBUG: blockerId: \(blockerId), blockedId: \(blockedId), reason: \(reason)")
		let isLoggedIn = UserAuthViewModel.shared.isLoggedIn
		let spawnUserId = UserAuthViewModel.shared.spawnUser?.id.uuidString ?? "nil"
		print("🚫 DEBUG: UserAuthViewModel.shared.isLoggedIn: \(isLoggedIn)")
		print(
			"🚫 DEBUG: UserAuthViewModel.shared.spawnUser: \(spawnUserId)"
		)

		// Check if we have access token in keychain
		if let accessTokenData = KeychainService.shared.load(key: "accessToken"),
			let accessToken = String(data: accessTokenData, encoding: .utf8)
		{
			print("🚫 DEBUG: Access token found in keychain: \(accessToken.prefix(20))...")
		} else {
			print("🚫 DEBUG: ⚠️ No access token found in keychain")
		}

		print("🚫 DEBUG: Making API call...")

		// Use DataService with WriteOperationType
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(
			.blockUser(blockerId: blockerId, blockedId: blockedId, reason: reason)
		)

		// Handle the result
		switch result {
		case .success:
			print("🚫 DEBUG: ✅ Block user request completed successfully")
		case .failure(let error):
			print("🚫 DEBUG: ❌ Block user request failed with error: \(error)")
			print("🚫 DEBUG: Error details: \(error)")
			throw error
		}
	}

	/// Unblock a user
	/// - Parameters:
	///   - blockerId: ID of the user doing the unblocking
	///   - blockedId: ID of the user being unblocked
	func unblockUser(blockerId: UUID, blockedId: UUID) async throws {
		// Use DataService with WriteOperationType
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(
			.unblockUser(blockerId: blockerId, blockedId: blockedId)
		)

		// Handle the result
		switch result {
		case .success:
			break  // Success
		case .failure(let error):
			throw error
		}
	}

	/// Get list of blocked users
	/// - Parameters:
	///   - blockerId: ID of the user whose blocked list to retrieve
	///   - returnOnlyIds: If true, returns only UUIDs; if false, returns full BlockedUserDTO objects
	/// - Returns: Either array of UUIDs or array of BlockedUserDTO objects
	func getBlockedUsers(blockerId: UUID, returnOnlyIds: Bool = false) async throws -> [UUID] {
		if returnOnlyIds {
			let result: DataResult<[UUID]> = await dataService.read(
				.blockedUsers(blockerId: blockerId, returnOnlyIds: true))
			switch result {
			case .success(let uuids, _):
				return uuids
			case .failure(let error):
				throw error
			}
		} else {
			let result: DataResult<[BlockedUserDTO]> = await dataService.read(
				.blockedUsers(blockerId: blockerId, returnOnlyIds: false))
			switch result {
			case .success(let blockedUsers, _):
				return blockedUsers.map { $0.blockedId }
			case .failure(let error):
				throw error
			}
		}
	}

	/// Get full blocked user details
	/// - Parameter blockerId: ID of the user whose blocked list to retrieve
	/// - Returns: Array of full BlockedUserDTO objects with user details
	func getFullBlockedUsers(blockerId: UUID) async throws -> [BlockedUserDTO] {
		let result: DataResult<[BlockedUserDTO]> = await dataService.read(
			.blockedUsers(blockerId: blockerId, returnOnlyIds: false))
		switch result {
		case .success(let blockedUsers, _):
			return blockedUsers
		case .failure(let error):
			throw error
		}
	}

	/// Check if a user is blocked
	/// - Parameters:
	///   - blockerId: ID of the user who might be blocking
	///   - blockedId: ID of the user who might be blocked
	/// - Returns: True if blocked, false otherwise
	func isUserBlocked(blockerId: UUID, blockedId: UUID) async throws -> Bool {
		let result: DataResult<Bool> = await dataService.read(
			.isUserBlocked(blockerId: blockerId, blockedId: blockedId))
		switch result {
		case .success(let isBlocked, _):
			return isBlocked
		case .failure(let error):
			throw error
		}
	}

	// MARK: - Reporting Users

	func reportUser(
		reporterUserId: UUID,
		reportedUserId: UUID,
		reportType: ReportType,
		description: String
	) async throws {
		let reportDTO = CreateReportedContentDTO(
			reporterUserId: reporterUserId,
			contentId: reportedUserId,
			contentType: .user,
			reportType: reportType,
			description: description
		)

		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(.reportUser(report: reportDTO))
		switch result {
		case .success:
			break  // Success
		case .failure(let error):
			throw error
		}
	}

	// MARK: - Reporting Chat Messages

	func reportChatMessage(
		reporterUserId: UUID,
		chatMessageId: UUID,
		reportType: ReportType,
		description: String
	) async throws {
		let reportDTO = CreateReportedContentDTO(
			reporterUserId: reporterUserId,
			contentId: chatMessageId,
			contentType: .chatMessage,
			reportType: reportType,
			description: description
		)

		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(
			.reportChatMessage(report: reportDTO))
		switch result {
		case .success:
			break  // Success
		case .failure(let error):
			throw error
		}
	}

	// MARK: - Reporting Activities

	func reportActivity(
		reporterUserId: UUID,
		activityId: UUID,
		reportType: ReportType,
		description: String
	) async throws {
		let reportDTO = CreateReportedContentDTO(
			reporterUserId: reporterUserId,
			contentId: activityId,
			contentType: .activity,
			reportType: reportType,
			description: description
		)

		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(
			.reportActivity(report: reportDTO))
		switch result {
		case .success:
			break  // Success
		case .failure(let error):
			throw error
		}
	}

	/// Get reports made by a user (simplified for "my reports" page)
	/// - Parameter reporterId: ID of the user whose reports to retrieve
	/// - Returns: Array of simplified reports made by the user
	func getReportsByUser(reporterId: UUID) async throws -> [FetchReportedContentDTO] {
		let result: DataResult<[FetchReportedContentDTO]> = await dataService.read(
			.reportsByUser(reporterId: reporterId))
		switch result {
		case .success(let reports, _):
			return reports
		case .failure(let error):
			throw error
		}
	}

	/// Get reports about a user (admin only)
	/// - Parameter userId: ID of the user to get reports about
	/// - Returns: Array of reports about the user
	func getReportsAboutUser(userId: UUID) async throws -> [ReportedContentDTO] {
		let result: DataResult<[ReportedContentDTO]> = await dataService.read(.reportsAboutUser(userId: userId))
		switch result {
		case .success(let reports, _):
			return reports
		case .failure(let error):
			throw error
		}
	}
}
