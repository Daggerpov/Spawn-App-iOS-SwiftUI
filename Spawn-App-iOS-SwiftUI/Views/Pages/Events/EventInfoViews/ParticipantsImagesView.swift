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
    let maxCount: Int = 2

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
		HStack(spacing: -8) {
			//Spacer()
            let participants: [BaseUserDTO] = participantsCleanup(participants: event.participantUsers ?? [])
			ForEach(
                0..<min(maxCount, participants.count),
				id: \.self
			) { participantIndex in
                let participant: BaseUserDTO = participants[participantIndex]
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
									.frame(width: 24, height: 24)
							}
						} else {
							Circle()
								.fill(Color.gray)
								.frame(width: 24, height: 24)
						}
					}
				)
			}
            if participants.count > maxCount {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                    Text("+\(participants.count - maxCount)")
                        .font(.onestSemiBold(size: 12))
                        .foregroundColor(figmaSoftBlue)
                }
                .shadow(radius: 2)
            }
		}
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	ParticipantsImagesView(event: FullFeedEventDTO.mockDinnerEvent).environmentObject(appCache)
}
