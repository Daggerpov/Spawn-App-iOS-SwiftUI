//
//  ChoosingTagViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Michael Tham on 23/1/25.
//

import Foundation

class ChooseTagPopUpViewModel: ObservableObject {
@Published var chooseTagErrorMessage: String = ""
@Published var tags: [FriendTag] = []
@Published var selectedTags: Set<UUID> = []

var userId: UUID

var apiService: IAPIService

init(userId: UUID, apiService: IAPIService) {
    self.userId = userId
    self.apiService = apiService
}

func addTagsToFriend(friendUserId: UUID) async {
    if let url = URL(
        string: APIService.baseURL + "friendTags/addUserToTags/\(userId)")
    {
        do {
            try await self.apiService.sendData(
                friendUserId,
                to: url,
                parameters: [
                    "friendUserId": friendUserId.uuidString
                ])
        } catch {
            await MainActor.run {
                chooseTagErrorMessage =
                    "There was an error select a tag for your friend. Please try again."
                print(apiService.errorMessage ?? "")
            }
        }
    }
}

func fetchTagsToAddToFriend(friendUserId: UUID) async {
    let urlString = APIService.baseURL + "friendTags/addUserToTags/\(userId)"
    
    if let url = URL(string: urlString) {
        let parameters: [String: String] = [
            "friendUserId": friendUserId.uuidString
        ]
    
        do {
            let fetchedTags: [FriendTag] = try await self.apiService.fetchData(
                from: url, parameters: parameters
            )

            await MainActor.run {
                self.tags = fetchedTags
            }
        } catch {
            if let statusCode = apiService.errorStatusCode,
                apiService.errorStatusCode != 404
            {
                print("Invalid status code from response: \(statusCode)")
                print(apiService.errorMessage ?? "")
            }
            await MainActor.run {
                self.tags = []
            }
        }
    }
}

func toggleTagSelection(_ tagId: UUID) {
    if selectedTags.contains(tagId) {
        selectedTags.remove(tagId)
    } else {
        selectedTags.insert(tagId)
    }
}
}

