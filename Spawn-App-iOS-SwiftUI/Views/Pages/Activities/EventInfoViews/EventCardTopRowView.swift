//
//  EventCardTopRowView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct EventCardTopRowView: View {
	var event: FullFeedEventDTO

	var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let title = event.title {
                    EventCardTitleView(eventTitle: title)
                }
                EventCardTimeView(event: event)
            }
            Spacer()
            ParticipantsImagesView(event: event)
        }
	}
}

struct EventCardTitleView: View {
	var eventTitle: String
	var body: some View {
		// TODO: make this title editable
        Text(eventTitle)
            .font(.onestBold(size: 24))
            .foregroundColor(.white)
	}
}

struct EventCardTimeView: View {
    @ObservedObject var viewModel: EventInfoViewModel
    
    init(event: FullFeedEventDTO) {
        self.viewModel = EventInfoViewModel(
            event: event, eventInfoType: .time)
    }
    
    var body: some View {
        Text(viewModel.eventInfoDisplayString)
            .font(.onestRegular(size: 14))
            .foregroundColor(.white.opacity(0.85))
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	EventCardTopRowView(event: FullFeedEventDTO.mockDinnerEvent).environmentObject(appCache)
}
