//
//  ParticipantsImagesView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI
import Foundation

struct ParticipantsImagesView: View {
    var event: Event
    
    var body: some View {
        // sort by creator first, then rest:
        let participants = [event.creator] + (event.participants ?? [])
            .sorted { participant1, participant2 in
                if participant1.id == event.creator.id { return true }
                // not sure if this line is actually necessary:
                if participant2.id == event.creator.id { return false }
                return false
            }
        
        HStack {
            Spacer()
            ForEach(participants, id: \.self.id) { participant in
                if let appUserParticipant = AppUserService.shared.appUserLookup[participant.id] {
                    NavigationLink(
                        destination: ProfileView(appUser: appUserParticipant),
                        label: {
                            if let profilePicture = appUserParticipant.profilePicture {
                                profilePicture
                                    .ProfileImageModifier(imageType: .eventParticipants)
                            }
                        }
                    )
                }
            }
        }
    }
}
