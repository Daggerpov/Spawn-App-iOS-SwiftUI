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
				if let title = event.title {
					EventCardTitleView(eventTitle: title)
				}
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

struct EventCardTitleView: View {
	var eventTitle: String
	var body: some View {
		// TODO: make this title editable
		Text(eventTitle)
			.font(.title2)
			.frame(alignment: .leading)
			.multilineTextAlignment(.leading)
	}
}
