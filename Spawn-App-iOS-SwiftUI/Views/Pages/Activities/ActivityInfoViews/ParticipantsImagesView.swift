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
    let maxCount: Int = 3  // Figma design specification
    // New: control avatar sizing by context (feed card vs popup/drawer)
    var imageType: ProfileImageType = .feedCardParticipants
    
    // New: compute size based on image type
    private var avatarSize: CGFloat {
        switch imageType {
        case .participantsPopup:
            return 42.33
        case .participantsDrawer:
            return 36
        case .feedCardParticipants:
            return 34
        default:
            return 34
        }
    }
    
    // Optional binding to control tab selection for current user navigation
    @Binding var selectedTab: TabType?
    
    // Simplified tap handler to avoid delays
    private func handleParticipantTap(_ participant: BaseUserDTO) {
        // Always show participants modal first, regardless of selectedTab
        NotificationCenter.default.post(name: .showParticipants, object: activity)
    }
    
    // Simplified handler for participants modal
    private func showParticipantsModal() {
        NotificationCenter.default.post(name: .showParticipants, object: activity)
    }
    
    init(activity: FullFeedActivityDTO, selectedTab: Binding<TabType?> = .constant(nil), imageType: ProfileImageType = .feedCardParticipants) {
        self.activity = activity
        self._selectedTab = selectedTab
        self.imageType = imageType
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
		HStack(spacing: -10.10) { // Figma design specification
			//Spacer()
            let participants: [BaseUserDTO] = participantsCleanup(participants: activity.participantUsers ?? [])
			ForEach(
                0..<min(maxCount, participants.count),
				id: \.self
			) { participantIndex in
                let participant: BaseUserDTO = participants[participantIndex]
                
                // Profile picture with tap gesture
                VStack {
                    if let pfpUrl = participant.profilePicture {
                        if MockAPIService.isMocking {
                            Image(pfpUrl)
                                .ProfileImageModifier(imageType: imageType)
                                .shadow(
                                    color: Color(red: 0, green: 0, blue: 0, opacity: 0.25),
                                    radius: 3.22,
                                    y: 1.29
                                )
                        } else {
                            CachedProfileImage(
                                userId: participant.id,
                                url: URL(string: pfpUrl),
                                imageType: imageType
                            )
                            .shadow(
                                color: Color(red: 0, green: 0, blue: 0, opacity: 0.25),
                                radius: 3.22,
                                y: 1.29
                            )
                        }
                    } else {
                        Ellipse()
                            .foregroundColor(.clear)
                            .frame(width: avatarSize, height: avatarSize)
                            .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                            .shadow(
                                color: Color(red: 0, green: 0, blue: 0, opacity: 0.25),
                                radius: 3.22,
                                y: 1.29
                            )
                    }
                }
                .onTapGesture {
                    // Simplified immediate action - no complex conditional logic
                    handleParticipantTap(participant)
                }
                .allowsHitTesting(true)
                .contentShape(Circle()) // Ensure hit testing is limited to circular area
			}
            
            if participants.count > maxCount {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: avatarSize, height: avatarSize)
                        .shadow(
                            color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), 
                            radius: 4.06, 
                            y: 1.62
                        )
                    
                    Text("+\(participants.count - maxCount)")
                        .font(Font.custom("SF Pro Display", size: 15.15).weight(.bold))
                        .foregroundColor(Color(red: 0.42, green: 0.51, blue: 0.98))
                }
                .onTapGesture {
                    showParticipantsModal()
                }
                .allowsHitTesting(true)
                .contentShape(Circle()) // Ensure hit testing is limited to circular area
            }
		}
	}
}

@available(iOS 17, *)
#Preview {
    ParticipantsImagesView(activity: FullFeedActivityDTO.mockDinnerActivity)
}
