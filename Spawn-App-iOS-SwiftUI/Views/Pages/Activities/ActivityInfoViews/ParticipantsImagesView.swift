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
    let width: CGFloat = 48
    let height: CGFloat = 48
    
    // Optional binding to control tab selection for current user navigation
    @Binding var selectedTab: TabType?
    
    init(activity: FullFeedActivityDTO, selectedTab: Binding<TabType?> = .constant(nil)) {
        self.activity = activity
        self._selectedTab = selectedTab
    }

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
				ProfilePictureView(user: participant, selectedTab: $selectedTab, allowsNavigation: false)
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
