//
//  EventInfoView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct EventTitleView: View {
    var event: Event
    
    var body: some View {
        VStack (spacing: 10) {
            HStack{
                Text(event.title)
                    .font(.title2)
                    .frame(alignment: .leading)
                    .multilineTextAlignment(.leading)
                Spacer()
                VStack{
                    ParticipantsImagesView(event: event)
                    Spacer()
                }
            }
        }
        .foregroundColor(.white)
        .frame(alignment: .leading)
    }
}

struct EventTimeView: View {
    var eventTime: String
    var body: some View {
        HStack{
            Text(eventTime)
                .cornerRadius(20)
                .font(.caption2)
                .frame(alignment: .leading)
            // TODO: surround by rounded rectangle
            Spacer()
        }
    }
}

struct EventLocationView: View {
    var event: Event

    var body: some View {
        if let eventLocation = event.location?.locationName {
            HStack{
                Image(systemName: "map")
                // TODO: surround by circle, per Figma design
                
                Text(eventLocation)
                    .lineLimit(1)
                    .fixedSize()
                    .font(.caption2)
                Spacer()
                
            }
            .frame(alignment: .leading)
            .font(.caption)
        }
    }
}

struct EventParticipateButtonView: View {
    var toggleParticipationCallback: () -> Void
    var isParticipating: Bool
    var color: Color
    var body: some View {
        Circle()
            .frame(width: 40, height: 40)
            .foregroundColor(.white)
            .background(Color.white)
            .clipShape(Circle())
            .overlay(
                Button(action: {
                    toggleParticipationCallback()
                }) {
                    Image(systemName: isParticipating ? "checkmark" : "star.fill")
                        .resizable()
                        .frame(width: 17.5, height: 17.5)
                        .clipShape(Circle())
                        .shadow(radius: 20)
                        .foregroundColor(color)
                }
            )
    }
}
