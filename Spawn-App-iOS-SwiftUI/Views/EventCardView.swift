//
//  EventCardView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import SwiftUI

struct EventCardView: View {
    @ObservedObject var viewModel: EventCardViewModel
    var user: User
    var event: Event
    var color: Color
    var callback: (Event, Color) -> Void
    
    init(user: User, event: Event, color: Color, callback: @escaping(Event, Color) -> Void) {
        self.User = User
        self.event = event
        self.color = color
        self.viewModel = EventCardViewModel(user: User, event: event)
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
							EventInfoView(event: event, eventInfoType: .time)
							Spacer()
						}
                        Spacer()
						HStack{
							EventInfoView(event: event, eventInfoType: .location)
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


