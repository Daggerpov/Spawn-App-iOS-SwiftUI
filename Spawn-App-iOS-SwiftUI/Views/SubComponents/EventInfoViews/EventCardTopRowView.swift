//
//  EventCardTopRowView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct EventCardTopRowView: View {
    var event: Event
    
    var body: some View {
        VStack (spacing: 10) {
            HStack{
                titleView
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

extension EventCardTopRowView {
    var titleView: some View {
        Text(event.title)
            .font(.title2)
            .frame(alignment: .leading)
            .multilineTextAlignment(.leading)
    }
}
