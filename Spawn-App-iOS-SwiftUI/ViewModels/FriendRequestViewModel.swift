//
//  FriendRequestViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shannon S on 2025-02-07.
//

import Foundation

class FriendRequestViewModel: ObservableObject {
    var apiService: IAPIService
    var userId: UUID
    var friendRequestId: UUID

	@Published var creationMessage: String = ""

    init(apiService: IAPIService, userId: UUID, friendRequestId: UUID) {
        self.apiService = apiService
        self.userId = userId
        self.friendRequestId = friendRequestId
    }
    
    /*
     // full path: /api/v1/users/{userId}/friend-requests/{friendRequestId}/accept
         
     
     @PutMapping("{userId}/friend-requests/{friendRequestId}/accept")
         public ResponseEntity<Void> acceptFriendRequest(@PathVariable UUID userId, @PathVariable UUID friendRequestId) {
     
     */
    func acceptFriendRequest() async -> Void {
        if let url = URL(string: APIService.baseURL + "users/\(userId)/friend-requests/\(friendRequestId)/accept") {
            do {
				let _: EmptyResponse = try await self.apiService.updateData(EmptyRequestBody(), to: url)
				print("accepted friend request at url: \(url.absoluteString)")
            } catch {
                await MainActor.run {
                    creationMessage = "There was an error accepting the friend request. Please try again"
                    print(apiService.errorMessage ?? "")
                }
            }
        }
    }

	func declineFriendRequest() async -> Void {
        if let url = URL(string: APIService.baseURL + "users/\(userId)/friend-requests/\(friendRequestId)/decline") {
            do {
				let _: EmptyResponse = try await self.apiService.updateData(EmptyRequestBody(), to: url)
				print("declined friend request at url: \(url.absoluteString)")
            } catch {
                await MainActor.run {
                    creationMessage = "There was an error declining the friend request. Please try again"
                    print(apiService.errorMessage ?? "")
                }
            }
        }
    }
}

struct EmptyRequestBody: Codable {}
struct EmptyResponse: Codable {}
