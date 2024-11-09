//
//  EventDescriptionView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct EventDescriptionView: View {
    var event: Event
    
    init(event: Event) {
        self.event = event
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Event Title: \(event.title)")
                        .font(.largeTitle)
                        .bold()
                    
                    if let startTime = event.startTime {
                        Text("Start Time: \(startTime)")
                            .font(.headline)
                    }
                    
                    if let endTime = event.endTime {
                        Text("End Time: \(endTime)")
                            .font(.headline)
                    }
                    
                    if let location = event.location {
                        Text("Location: \(location.locationName)")
                            .font(.subheadline)
                    }
                    
                    if let note = event.note {
                        Text("Note: \(note)")
                            .font(.body)
                    }
                    
                    Text("Creator: \(event.creator.id.uuidString)") // You can display the name or other properties if available
                    
                    if let participants = event.participants, !participants.isEmpty {
                        Text("Participants:")
                            .font(.headline)
                        ForEach(participants, id: \.id) { participant in
                            Text("- \(participant.id.uuidString)") // Replace `id` with `name` or other properties if available
                        }
                    }
                    
                    if let invited = event.invited, !invited.isEmpty {
                        Text("Invited:")
                            .font(.headline)
                        ForEach(invited, id: \.id) { invitee in
                            Text("- \(invitee.id.uuidString)") // Replace `id` with `name` or other properties if available
                        }
                    }
                }
                .padding()
                .navigationTitle("Event Details")
            }
        }
    }
}
