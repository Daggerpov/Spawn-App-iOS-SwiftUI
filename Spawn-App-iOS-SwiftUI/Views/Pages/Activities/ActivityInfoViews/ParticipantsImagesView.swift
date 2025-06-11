//
//  ParticipantsImagesView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation
import SwiftUI

struct ParticipantsImagesView: View {
	var activity: FullFeedActivityDTO
    let maxCount: Int = 2
    let width: CGFloat = 28
    let height: CGFloat = 28

	func participantsCleanup(participants: [BaseUserDTO]) -> [BaseUserDTO] {
		var participantsFiltered = participants

		let userCreator: BaseUserDTO = activity.creatorUser
		// Remove the creator if already in the list
		participantsFiltered.removeAll { $0.id == userCreator.id }

		// Prepend the creator to the participants list
		participantsFiltered.insert(
			activity.creatorUser, at: 0)


		return participantsFiltered
	}

	var body: some View {
		HStack(spacing: -8) {
			//Spacer()
            let participants: [BaseUserDTO] = participantsCleanup(participants: activity.participantUsers ?? [])
			ForEach(
                0..<min(maxCount, participants.count),
				id: \.self
			) { participantIndex in
                let participant: BaseUserDTO = participants[participantIndex]
				NavigationLink(
					destination: ProfileView(user: participant),
					label: {
						if let pfpUrl = participant.profilePicture {
                            if MockAPIService.isMocking {
                                Image(pfpUrl)
                                    .ProfileImageModifier(imageType: .activityParticipants)
                            } else {
                                AsyncImage(url: URL(string: pfpUrl)) { image in
                                    image.ProfileImageModifier(imageType: .activityParticipants)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: width, height: height)
                                }
                            }
						} else {
							Circle()
								.fill(Color.gray)
								.frame(width: width, height: height)
						}
					}
				)
			}
            
            if participants.count > maxCount {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: width, height: height)
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
	ParticipantsImagesView(activity: FullFeedActivityDTO.mockDinnerActivity).environmentObject(appCache)
}
