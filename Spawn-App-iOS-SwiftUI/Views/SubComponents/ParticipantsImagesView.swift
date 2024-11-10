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
    
    func participantsCleanup(participants: [User]) -> [User]{
        var parties = participants
        // Remove the creator if already in the list
        parties.removeAll { $0.id == event.creator.id }
        
        // Prepend the creator to the participants list
        parties.insert(event.creator, at: 0)
        
        // Sort the rest of the participants (if necessary)
        parties.sort { participant1, participant2 in
            // Creator is already at the front, so this sorting can handle the rest
            return false // maintain original order
        }
        return parties
    }
    
    var body: some View {
        HStack {
            Spacer()
            ForEach(participantsCleanup(participants: event.participants ?? []), id: \.self.id) { participant in
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
