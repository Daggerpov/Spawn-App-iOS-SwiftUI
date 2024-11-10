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
    var callback: (Event, Color) -> Void
    
    init(appUser: AppUser, event: Event, color: Color, callback: @escaping(Event, Color) -> Void) {
        self.appUser = appUser
        self.event = event
        self.color = color
        self.viewModel = EventCardViewModel(appUser: appUser, event: event)
        self.callback = callback
    }
    var body: some View {
        NavigationStack{
            VStack{
                EventTitleView(event: event)
                Spacer()
                HStack{
                    VStack{
                        EventTimeView(event: event)
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
            .onTapGesture {
                callback(event, color)
            }
        }
    }
    
}


