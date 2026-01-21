//
//  MinimalFriendDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

/// A minimal DTO for friend users, containing only the essential fields needed
/// for displaying friends in selection lists (e.g., activity creation, activity types).
///
/// This DTO significantly reduces memory usage compared to FullFriendUserDTO by
/// excluding fields like bio and email that are unnecessary for friend selection UIs.
///
/// Fields included:
/// - id: Required for selection/identification
/// - username: Displayed as @username
/// - name: Displayed as the friend's name
/// - profilePicture: URL for avatar display
struct MinimalFriendDTO: Identifiable, Codable, Hashable, Nameable, Sendable {
	static func == (lhs: MinimalFriendDTO, rhs: MinimalFriendDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var username: String?
	var name: String?
	var profilePicture: String?

	init(
		id: UUID,
		username: String? = nil,
		name: String? = nil,
		profilePicture: String? = nil
	) {
		self.id = id
		self.username = username
		self.name = name
		self.profilePicture = profilePicture
	}

	/// Convert to FullFriendUserDTO when full data is needed
	/// Note: bio and email will be nil since they're not available in MinimalFriendDTO
	func toFullFriendUserDTO() -> FullFriendUserDTO {
		return FullFriendUserDTO(
			id: id,
			username: username,
			profilePicture: profilePicture,
			name: name,
			bio: nil,
			email: nil
		)
	}

	/// Convert to BaseUserDTO when needed for compatibility
	/// Note: bio and email will be nil since they're not available in MinimalFriendDTO
	var asBaseUser: BaseUserDTO {
		return BaseUserDTO(
			id: id,
			username: username,
			profilePicture: profilePicture,
			name: name,
			bio: nil,
			email: nil
		)
	}

	/// Create from FullFriendUserDTO (drops bio and email to save memory)
	static func from(_ fullFriend: FullFriendUserDTO) -> MinimalFriendDTO {
		return MinimalFriendDTO(
			id: fullFriend.id,
			username: fullFriend.username,
			name: fullFriend.name,
			profilePicture: fullFriend.profilePicture
		)
	}

	/// Create from BaseUserDTO (drops bio and email to save memory)
	static func from(_ baseUser: BaseUserDTO) -> MinimalFriendDTO {
		return MinimalFriendDTO(
			id: baseUser.id,
			username: baseUser.username,
			name: baseUser.name,
			profilePicture: baseUser.profilePicture
		)
	}
}

// MARK: - Mock Data for Previews

extension MinimalFriendDTO {
	static let danielAgapov: MinimalFriendDTO = MinimalFriendDTO(
		id: UUID(uuidString: "7CF00DD1-D246-4339-8B85-0EC589161DBF") ?? UUID(),
		username: "daggerpov",
		name: "Daniel Agapov",
		profilePicture: "Daniel_Agapov_pfp"
	)

	static let danielLee: MinimalFriendDTO = MinimalFriendDTO(
		id: UUID(uuidString: "8DF11EE2-E357-5440-9C96-1FD690272ECF") ?? UUID(),
		username: "uhdlee",
		name: "Daniel Lee",
		profilePicture: "Daniel_Lee_pfp"
	)

	static let haley: MinimalFriendDTO = MinimalFriendDTO(
		id: UUID(uuidString: "9EF22FF3-F468-6551-AD07-2FE7A1383FDA") ?? UUID(),
		username: "haleyusername",
		name: "Haley",
		profilePicture: "Haley_pfp"
	)

	static let mockUsers: [MinimalFriendDTO] = [danielAgapov, danielLee, haley]
}
