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
    var user: User
    var event: Event

	init(apiService: IAPIService, user: User, event: Event) {
		self.apiService = apiService
        self.user = user
        self.event = event
    }
    
    /// returns whether the logged in app user is part of the event's participants array
    public func fetchIsParticipating() -> Void {
        self.isParticipating = ((event.participantUsers?.contains(where: { user in
            user.id == user.id
        })) != nil)

    }
    
	/// Toggles the user's participation status in the event
	public func toggleParticipation() async {
		let urlString = "\(APIService.baseURL)events/\(event.id)/toggleStatus/\(user.id)"
		guard let url = URL(string: urlString) else {
			print("Invalid URL")
			return
		}

		do {
			// Send a PUT request and receive the updated event in response
			let updatedEvent: Event = try await apiService.updateData(EmptyBody(), to: url)

			// Update local state after a successful API call
			await MainActor.run {
				self.event = updatedEvent
				self.isParticipating.toggle()
			}
		} catch {
			await MainActor.run {
				print("Error toggling participation: \(error.localizedDescription)")
			}
		}
	}
}

struct EmptyBody: Codable {}
