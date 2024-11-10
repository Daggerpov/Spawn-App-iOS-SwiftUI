//
//  EventCardView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import SwiftUI

struct EventCardView: View {
    @ObservedObject var viewModel: EventCardViewModel
    var event: Event
    var color: Color
    
    init(event: Event, color: Color) {
        self.event = event
        self.color = color
        viewModel = EventCardViewModel(event: event)
    }
    var body: some View {
        NavigationStack{
            NavigationLink(destination: EventDescriptionView(event: event, appUsers: AppUser.mockAppUsers, color: color)) {
                VStack{
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
                    
                    Spacer()
                    HStack{
                        VStack{
                            HStack{
                                Text(viewModel.eventTimeDisplayString)
                                    .cornerRadius(20)
                                    .font(.caption2)
                                    .frame(alignment: .leading)
                                // TODO: surround by rounded rectangle
                                Spacer()
                            }
                            
                            Spacer()
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
                        .foregroundColor(.white)
                        Spacer()
                        Circle()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(
                                // TODO: obviously change `Bool.random()` later to proper logic
                                // proper logic: (if user is in `Event`'s `participants`)
                                Image(systemName: Bool.random() ? "checkmark" : "star.fill")
                                    .resizable()
                                    .frame(width: 17.5, height: 17.5)
                                    .clipShape(Circle())
                                    .shadow(radius: 20)
                                    .foregroundColor(color)
                            )
                    }
                    .frame(alignment: .trailing)
                }
                .padding(20)
                .background(color)
                .cornerRadius(10)
            }
        }
    }
}


