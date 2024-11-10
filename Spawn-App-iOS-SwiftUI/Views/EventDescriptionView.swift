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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and Time Information
                EventTitleView(event: viewModel.event)
                
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        EventTimeView(event: viewModel.event)
                        EventLocationView(event: viewModel.event)
                    }
                    .foregroundColor(.white)
                    
                    Spacer() // Ensures alignment but doesn't add spacing below the content
                }
                
                // Start and End Time
                if let startTime = viewModel.event.startTime {
                    Text("Start Time: \(startTime)")
                        .font(.headline)
                }
                
                if let endTime = viewModel.event.endTime {
                    Text("End Time: \(endTime)")
                        .font(.headline)
                }
                
                // Location
                if let location = viewModel.event.location {
                    Text("Location: \(location.locationName)")
                        .font(.subheadline)
                }
                
                // Note
                if let note = viewModel.event.note {
                    Text("Note: \(note)")
                        .font(.body)
                }
                
                // Creator Information
                Text("Creator: \(AppUserService.shared.appUserLookup[viewModel.event.creator.id]?.username ?? viewModel.event.creator.id.uuidString)")
                    .font(.body)
                
                // Invited Users
                if let invited = viewModel.event.invited, !invited.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Invited:")
                            .font(.headline)
                        ForEach(invited, id: \.id) { invitee in
                            Text("- \(AppUserService.shared.appUserLookup[invitee.id]?.username ?? invitee.id.uuidString)")
                        }
                    }
                }
            }
            .padding(20)
            .background(color)
            .cornerRadius(10)
        }
        .padding(.horizontal) // Reduces padding on the bottom
    }
}
