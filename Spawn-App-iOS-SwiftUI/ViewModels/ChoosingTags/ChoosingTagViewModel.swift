//
//  ChoosingTagViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Michael Tham on 23/1/25.
//

import Foundation

class ChooseTagPopUpViewModel: ObservableObject {
	@Published var chooseTagErrorMessage: String = ""

	//TODO: figure out functions

	var apiService: IAPIService

	init(apiService: IAPIService) {
		self.apiService = apiService
	}

	func addTagsToFriend(friendUserId: UUID, friendTagIds: [UUID]) async {
		if let url = URL(
			string: APIService.baseURL + "friendTags/addUserToTags")
		{
			do {
				// Convert the UUID array to an array of strings
				let friendTagIdsString = friendTagIds.map { $0.uuidString }

				try await self.apiService.sendData(
					EmptyBody(), to: url,
					parameters: [
						"userId": friendUserId.uuidString as AnyObject,
						"friendTagIds": friendTagIdsString as AnyObject,
					])
			} catch {
				await MainActor.run {
					chooseTagErrorMessage =
						"There was an error selecting a tag for your friend. Please try again."
					print(apiService.errorMessage ?? "")
				}
			}
		}
	}
}
