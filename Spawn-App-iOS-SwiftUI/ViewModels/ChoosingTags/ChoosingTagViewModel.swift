//
//  ChoosingTagViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Michael Tham on 23/1/25.
//

import Foundation

class ChooseTagPopUpViewModel: ObservableObject {
	@Published var chooseTagErrorMessage: String = ""
    //TODO: make new published var for tags
//    @Published var tags: [Tag] = []

	//TODO: figure out functions

	var apiService: IAPIService

	init(apiService: IAPIService) {
		self.apiService = apiService
	}

	func AddTagsToFriend(friendUserId: UUID, friendTagIds: [UUID]) async {
		if let url = URL(
			string: APIService.baseURL + "friendTags/addUserToTags")
		{
			do {
				try await self.apiService.sendData(
					friendTagIds,
					to: url,
					parameters: [
						"userId": friendUserId.uuidString
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
    
    func fetchTags(friendUserId: UUID, friendTagIds: [UUID]) async {
        if let url = URL(
            string: APIService.baseURL + "friendTags/addUserToTags")
        {
            do {
                let fetchedTags: [User] = try await self.apiService.fetchData(
                    from: url,
                    parameters: nil)
            } catch {
                await MainActor.run {
                    chooseTagErrorMessage =
                        "There was an error showing your tags. Please try again."
                    print(apiService.errorMessage ?? "")
                }
            }
        }
    }
}
