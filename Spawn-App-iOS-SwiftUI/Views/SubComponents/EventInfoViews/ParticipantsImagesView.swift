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

	// TODO DANIEL: maybe revisit this logic later
    func participantsCleanup(participants: [User]) -> [User]{
        var participantsFiltered = participants
        // Remove the creator if already in the list
		let userCreator: User = event.creatorUser ?? User.danielAgapov
        participantsFiltered.removeAll { $0.id == userCreator.id }

        // Prepend the creator to the participants list
		participantsFiltered.insert(event.creatorUser ?? User.danielAgapov, at: 0)

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
            ForEach(participantsCleanup(participants: event.participantUsers ?? []), id: \.self.id) { participant in
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
