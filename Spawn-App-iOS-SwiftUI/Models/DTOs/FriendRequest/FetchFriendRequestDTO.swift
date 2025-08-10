//
//  FriendRequestDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

/// as defined in the back-end `FetchFriendRequestDTO.java`
struct FetchFriendRequestDTO: Identifiable, Codable, Hashable {
    static func == (lhs: FetchFriendRequestDTO, rhs: FetchFriendRequestDTO) -> Bool {
        return lhs.id == rhs.id
    }

    var id: UUID
    var senderUser: BaseUserDTO
    var mutualFriendCount: Int?

    init(id: UUID = UUID(), senderUser: BaseUserDTO, mutualFriendCount: Int? = 0) {
        self.id = id
        self.senderUser = senderUser
        self.mutualFriendCount = mutualFriendCount
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case senderUser
        case mutualFriendCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try to decode UUID directly; if null or missing, generate a new one
        if let uuid = try? container.decode(UUID.self, forKey: .id) {
            self.id = uuid
        } else if let idString = try? container.decodeIfPresent(String.self, forKey: .id),
                  let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            // Backend occasionally returns null id; use zero UUID sentinel and let callers filter
            self.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        }
        self.senderUser = try container.decode(BaseUserDTO.self, forKey: .senderUser)
        self.mutualFriendCount = try container.decodeIfPresent(Int.self, forKey: .mutualFriendCount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(senderUser, forKey: .senderUser)
        try container.encodeIfPresent(mutualFriendCount, forKey: .mutualFriendCount)
    }
}

extension FetchFriendRequestDTO {
    static let mockFriendRequests: [FetchFriendRequestDTO] = [
        FetchFriendRequestDTO(
            id: UUID(), senderUser: BaseUserDTO.danielAgapov),
        FetchFriendRequestDTO(
            id: UUID(),
            senderUser: BaseUserDTO.danielLee,
            mutualFriendCount: 2
        )
    ]
    
    static let mockSentFriendRequests: [FetchFriendRequestDTO] = [
        FetchFriendRequestDTO(
            id: UUID(), senderUser: BaseUserDTO.haley),
        FetchFriendRequestDTO(
            id: UUID(),
            senderUser: BaseUserDTO.danielAgapov,
            mutualFriendCount: 1
        )
    ]
    
    // Alias for consistency
    static let mockOutgoingFriendRequests: [FetchFriendRequestDTO] = mockSentFriendRequests
}
