//
//  ParticipantsImagesView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation
import SwiftUI

struct ParticipantsImagesView: View {
	var event: FullFeedEventDTO

	func participantsCleanup(participants: [BaseUserDTO]) -> [BaseUserDTO] {
		var participantsFiltered = participants

		let userCreator: BaseUserDTO = event.creatorUser
		// Remove the creator if already in the list
		participantsFiltered.removeAll { $0.id == userCreator.id }

		// Prepend the creator to the participants list
		participantsFiltered.insert(
			event.creatorUser, at: 0)


		return participantsFiltered
	}

	var body: some View {
		HStack {
			Spacer()
			ForEach(
				participantsCleanup(participants: event.participantUsers ?? []),
				id: \.self.id
			) { participant in
				NavigationLink(
					destination: ProfileView(user: participant),
					label: {
						if let pfpUrl = participant.profilePicture {
							AsyncImage(url: URL(string: pfpUrl)) {
								image in
								image
									.ProfileImageModifier(
										imageType: .eventParticipants)
							} placeholder: {
								Circle()
									.fill(Color.gray)
									.frame(width: 25, height: 25)
							}
						} else {
							Circle()
								.fill(Color.gray)
								.frame(width: 25, height: 25)
						}
					}
				)
			}
		}
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	ParticipantsImagesView(event: FullFeedEventDTO.mockDinnerEvent).environmentObject(appCache)
}
