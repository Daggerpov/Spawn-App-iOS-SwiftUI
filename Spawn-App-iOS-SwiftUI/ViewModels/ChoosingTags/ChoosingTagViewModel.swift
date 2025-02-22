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
    @Published var tags: [UUID] = []

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
    
    func fetchTagsToAddToFriend(friendUserId: UUID) async {
        let urlString = APIService.baseURL + "friendTags/addUserToTags"
        
        if let url = URL(string: urlString) {
            let parameters: [String: String] = [
                "userId": friendUserId.uuidString
            ]
        
            do {
                let fetchedTags: [UUID] = try await self.apiService.fetchData(
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
}

