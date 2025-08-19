//
//  FetchSentFriendRequestDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

/// as defined in the back-end `FetchSentFriendRequestDTO.java`
struct FetchSentFriendRequestDTO: Identifiable, Codable, Hashable {
    static func == (lhs: FetchSentFriendRequestDTO, rhs: FetchSentFriendRequestDTO) -> Bool {
        return lhs.id == rhs.id
    }

    var id: UUID
    var receiverUser: BaseUserDTO

    init(id: UUID = UUID(), receiverUser: BaseUserDTO) {
        self.id = id
        self.receiverUser = receiverUser
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case receiverUser
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode receiver first
        let decodedReceiverUser = try container.decode(BaseUserDTO.self, forKey: .receiverUser)

        // Try to decode UUID directly; if null or missing, throw an error instead of using receiver ID
        if let uuid = try? container.decode(UUID.self, forKey: .id) {
            self.id = uuid
        } else if let idString = try? container.decodeIfPresent(String.self, forKey: .id),
                  let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            // If friend request ID is missing or invalid, this indicates a backend serialization issue
            // Don't use receiver ID as fallback since it causes API calls to fail with wrong ID
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [CodingKeys.id],
                    debugDescription: "Friend request ID is missing or invalid. Cannot use receiver ID as fallback."
                )
            )
        }

        self.receiverUser = decodedReceiverUser
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(receiverUser, forKey: .receiverUser)
    }
}

extension FetchSentFriendRequestDTO {
    static let mockSentFriendRequests: [FetchSentFriendRequestDTO] = [
        FetchSentFriendRequestDTO(
            id: UUID(), receiverUser: BaseUserDTO.haley),
        FetchSentFriendRequestDTO(
            id: UUID(),
            receiverUser: BaseUserDTO.danielAgapov
        )
    ]
    
    // Alias for consistency
    static let mockOutgoingFriendRequests: [FetchSentFriendRequestDTO] = mockSentFriendRequests
}
