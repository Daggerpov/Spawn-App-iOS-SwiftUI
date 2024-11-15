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
                EventCardTopRowView(event: event)
                Spacer()
                HStack{
					VStack{
						HStack{
							EventTimeView(event: event).fixedSize()
							Spacer()
						}
                        Spacer()
						HStack{
							EventLocationView(event: event).fixedSize()
							Spacer()
						}
                    }
                    .foregroundColor(.white)
                    Spacer()
                        .frame(width: 30)
                    Circle()
                        .CircularButton(systemName: viewModel.isParticipating ? "checkmark" : "star.fill", buttonActionCallback: {
                            viewModel.toggleParticipation()
                        })
                }
                .frame(alignment: .trailing)
            }
            .padding(20)
            .background(color)
            .cornerRadius(universalRectangleCornerRadius)
            .onAppear {
                viewModel.fetchIsParticipating()
            }
            .onTapGesture {
                callback(event, color)
            }
        }
    }
    
}


