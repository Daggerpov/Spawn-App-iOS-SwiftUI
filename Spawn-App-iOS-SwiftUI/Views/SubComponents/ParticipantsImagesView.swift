//
//  ParticipantsImagesView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ParticipantsImagesView: View {
    var event: Event
    
    var body: some View {
        if let participants = event.participants {
            HStack{
                Spacer()
                ForEach(participants, id: \.self.id) { participant in
                    if let appUser: AppUser = AppUserService.shared.appUserLookup[participant.id] {
                        if let profilePicture = appUser.profilePicture {
                            profilePicture
                            .resizable()
                            .frame(width: 25, height: 25)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            .shadow(radius: 10)
                        }
                    }
                }
            }
        }
    }
}
