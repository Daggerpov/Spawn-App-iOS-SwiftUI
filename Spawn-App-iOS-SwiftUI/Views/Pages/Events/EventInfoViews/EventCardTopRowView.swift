//
//  EventCardTopRowView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct EventCardTopRowView: View {
	var event: FullFeedEventDTO
    let subtitleFontSize: CGFloat = 14
    let subtitleColor: Color = .white.opacity(0.85)
    let viewModel: ActivityInfoViewModel
    
    init(event: FullFeedEventDTO) {
        self.event = event
        self.viewModel = ActivityInfoViewModel(activity: event)
    }

	var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let title = event.title {
                    EventCardTitleView(eventTitle: title)
                }
                eventSubtitleView
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

extension EventCardTopRowView {
    var eventSubtitleView: some View {
        Text("By ")
            .font(.onestRegular(size: subtitleFontSize))
            .foregroundColor(subtitleColor) +
        Text(event.creatorUser.name ?? event.creatorUser.username)
            .font(.onestSemiBold(size: subtitleFontSize))
            .foregroundColor(subtitleColor) +
        Text(" • \(viewModel.getDisplayString(activityInfoType: .time))")
            .font(.onestRegular(size: subtitleFontSize))
            .foregroundColor(subtitleColor)
    }
}



@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	EventCardTopRowView(event: FullFeedEventDTO.mockDinnerEvent).environmentObject(appCache)
}
