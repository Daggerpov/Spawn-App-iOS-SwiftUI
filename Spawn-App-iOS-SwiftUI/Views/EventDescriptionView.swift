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
                
                // Note
                if let note = viewModel.event.note {
                    Text("Note: \(note)")
                        .font(.body)
                }
            }
            .padding(20)
            .background(color)
            .cornerRadius(10)
        }
        .padding(.horizontal) // Reduces padding on the bottom
        .padding(.top, 200)
    }
}
