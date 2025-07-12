//
//  ActivityCardViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class ActivityCardViewModel: ObservableObject {
	@Published var isParticipating: Bool = false
	var apiService: IAPIService
	var userId: UUID
    var activity: FullFeedActivityDTO
    
    
	init(apiService: IAPIService, userId: UUID, activity: FullFeedActivityDTO) {
		self.apiService = apiService
		self.userId = userId
		self.activity = activity
		// Initialize the participation status correctly
		fetchIsParticipating()
	}

	/// returns whether the logged in app user is participating in the activity
	public func fetchIsParticipating() {
		// Use the participationStatus from the activity DTO instead of checking the participants array
		self.isParticipating = activity.participationStatus == .participating
	}

	/// Toggles the user's participation status in the activity
	public func toggleParticipation() async {
        if userId == activity.creatorUser.id {
            // Don't allow the creator to revoke participation in their event
            return
        }
		let urlString =
			"\(APIService.baseURL)activities/\(activity.id)/toggleStatus/\(userId)"
		guard let url = URL(string: urlString) else {
			print("Invalid URL")
			return
		}

		do {
			// Send a PUT request and receive the updated activity in response
			let updatedActivity: FullFeedActivityDTO = try await apiService.updateData(
				EmptyBody(), to: url, parameters: nil)

			// Update local state after a successful API call
			await MainActor.run {
				self.activity = updatedActivity
				// Derive the participation status from the updated activity instead of toggling
				self.isParticipating = updatedActivity.participationStatus == .participating
				
				// Update the cache with the updated activity so all views stay in sync
				AppCache.shared.addOrUpdateActivity(updatedActivity)
			}
		} catch {
			await MainActor.run {
				print(
					"Error toggling participation: \(error.localizedDescription)"
				)
			}
		}
	}
}

struct EmptyBody: Codable {} 
