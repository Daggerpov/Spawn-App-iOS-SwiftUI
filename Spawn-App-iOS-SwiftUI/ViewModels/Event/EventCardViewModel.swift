//
//  EventCardViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class EventCardViewModel: ObservableObject {
	@Published var isParticipating: Bool = false
	var apiService: IAPIService
	var userId: UUID
	var event: FullFeedEventDTO

	init(apiService: IAPIService, userId: UUID, event: FullFeedEventDTO) {
		self.apiService = apiService
		self.userId = userId
		self.event = event
	}

	/// returns whether the logged in app user is part of the event's participants array
	public func fetchIsParticipating() {
		self.isParticipating =
			((event.participantUsers?.contains(where: { user in
				user.id == userId
			})) != nil)

	}

	/// Toggles the user's participation status in the event
	public func toggleParticipation() async {
		let urlString =
			"\(APIService.baseURL)events/\(event.id)/toggleStatus/\(userId)"
		guard let url = URL(string: urlString) else {
			print("Invalid URL")
			return
		}

		do {
			// Send a PUT request and receive the updated event in response
			let updatedEvent: FullFeedEventDTO = try await apiService.updateData(
				EmptyBody(), to: url, parameters: nil)

			// Update local state after a successful API call
			await MainActor.run {
				self.event = updatedEvent
				self.isParticipating.toggle()
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
