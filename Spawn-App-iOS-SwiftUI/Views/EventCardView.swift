//
//  EventCardView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import SwiftUI

struct EventCardView: View {
    @ObservedObject var viewModel: EventCardViewModel
    var appUser: AppUser
    var event: Event
    var color: Color
    
    init(appUser: AppUser, event: Event, color: Color) {
        self.appUser = appUser
        self.event = event
        self.color = color
        viewModel = EventCardViewModel(appUser: appUser, event: event)
    }
    var body: some View {
        NavigationStack{
            NavigationLink(destination: EventDescriptionView(event: event, appUsers: AppUser.mockAppUsers, color: color)) {
                VStack{
                    EventTitleView(event: event)
                    Spacer()
                    HStack{
                        VStack{
                            EventTimeView(eventTime: viewModel.eventTimeDisplayString)
                            
                            Spacer()
                            EventLocationView(event: event)
                        }
                        .foregroundColor(.white)
                        Spacer()
                        EventParticipateButtonView(
                            toggleParticipationCallback: {
                                viewModel.toggleParticipation()
                            },
                            isParticipating: viewModel.isParticipating,
                            color: color
                        )
                    }
                    .frame(alignment: .trailing)
                }
                .padding(20)
                .background(color)
                .cornerRadius(10)
                .onAppear {
                    viewModel.fetchIsParticipating()
                }
            }
        }
    }
        
}


