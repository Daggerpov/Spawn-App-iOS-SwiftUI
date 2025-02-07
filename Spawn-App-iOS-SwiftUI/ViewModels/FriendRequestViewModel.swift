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
//        if let url = URL(string: APIService.baseURL + "") {
//            do {
//                try await self.apiService.sendData(event, to: url, parameters: nil)
//            } catch {
//                await MainActor.run {
//                    creationMessage = "There was an error creating your event. Please try again"
//                    print(apiService.errorMessage ?? "")
//                }
//            }
//        }
    }
}
