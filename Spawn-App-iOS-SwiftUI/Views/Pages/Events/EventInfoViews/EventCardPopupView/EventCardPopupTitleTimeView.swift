//
//  EventCardPopupTitleTimeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/19/25.
//


import SwiftUI

struct EventCardPopupTitleTimeView: View {
    var eventTitle: String
    var eventTime: String
    
    init(event: FullFeedEventDTO) {
        eventTitle = event.title ?? "@\(event.creatorUser.username)'s Event"
        eventTime = EventInfoViewModel(event: event, eventInfoType: .time).eventInfoDisplayString
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eventTitle)
                    .font(.onestSemiBold(size: 24))
                    .foregroundColor(.white)
                Text(eventTime) // TODO: Format time
                    .font(.onestRegular(size: 15))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal)
//            .padding(.bottom, 18)
            Spacer()
        }
        
    }
}
