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
        var participantsFiltered = participants
        // Remove the creator if already in the list
        participantsFiltered.removeAll { $0.id == event.creator.id }
        
        // Prepend the creator to the participants list
        participantsFiltered.insert(event.creator, at: 0)
        
        // Sort the rest of the participants (if necessary)
        participantsFiltered.sort { participant1, participant2 in
            // Creator is already at the front, so this sorting can handle the rest
            return false // maintain original order
        }
        return participantsFiltered
    }
    
    var body: some View {
        HStack {
            Spacer()
            ForEach(participantsCleanup(participants: event.participants ?? []), id: \.self.id) { participant in
                NavigationLink(
                    destination: ProfileView(user: participant),
                    label: {
                        if let profilePictureString = participant.profilePicture {
                            Image(profilePictureString)
                                .ProfileImageModifier(imageType: .eventParticipants)
                        }
                    }
                )
            }
        }
    }
}
