//
//  EventCardTopRowView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct EventCardTopRowView: View {
	var activity: FullFeedActivityDTO
    let subtitleFontSize: CGFloat = 14
    let subtitleColor: Color = .white.opacity(0.85)
    let viewModel: ActivityInfoViewModel
    
    init(activity: FullFeedActivityDTO) {
        self.activity = activity
        self.viewModel = ActivityInfoViewModel(activity: activity)
    }

	var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let title = activity.title {
                    EventCardTitleView(eventTitle: title)
                }
                eventSubtitleView
            }
            Spacer()
            ParticipantsImagesView(activity: activity)
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
        Text(activity.creatorUser.name ?? activity.creatorUser.username)
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
    EventCardTopRowView(activity: FullFeedActivityDTO.mockDinnerActivity).environmentObject(appCache)
}
