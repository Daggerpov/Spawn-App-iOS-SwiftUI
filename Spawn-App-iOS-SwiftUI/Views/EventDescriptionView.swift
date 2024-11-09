//
//  EventDescriptionView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct EventDescriptionView: View {
    @ObservedObject var viewModel: EventDescriptionViewModel
    
    var color: Color
    
    init(event: Event, appUsers: [AppUser], color: Color) {
        self.viewModel = EventDescriptionViewModel(event: event, appUsers: appUsers)
        self.color = color
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Event Title: \(viewModel.event.title)")
                        .font(.largeTitle)
                        .bold()
                    
                    if let startTime = viewModel.event.startTime {
                        Text("Start Time: \(startTime)")
                            .font(.headline)
                    }
                    
                    if let endTime = viewModel.event.endTime {
                        Text("End Time: \(endTime)")
                            .font(.headline)
                    }
                    
                    if let location = viewModel.event.location {
                        Text("Location: \(location.locationName)")
                            .font(.subheadline)
                    }
                    
                    if let note = viewModel.event.note {
                        Text("Note: \(note)")
                            .font(.body)
                    }
                    
                    Text("Creator: \(viewModel.appUserLookup[viewModel.event.creator.id]?.username ?? viewModel.event.creator.id.uuidString)")
                    
                    if let participants = viewModel.event.participants, !participants.isEmpty {
                        Text("Participants:")
                            .font(.headline)
                        ForEach(participants, id: \.id) { participant in
                            if let appUser = viewModel.appUserLookup[participant.id] {
                                Text("- \(appUser.username)")
                            } else {
                                Text("- \(participant.id.uuidString)")
                            }
                        }
                    }
                    
                    if let invited = viewModel.event.invited, !invited.isEmpty {
                        Text("Invited:")
                            .font(.headline)
                        ForEach(invited, id: \.id) { invitee in
                            if let appUser = viewModel.appUserLookup[invitee.id] {
                                Text("- \(appUser.username)")
                            } else {
                                Text("- \(invitee.id.uuidString)")
                            }
                        }
                    }
                }
                .padding()
                .navigationTitle("Event Details")
            }
        }
    }
}
