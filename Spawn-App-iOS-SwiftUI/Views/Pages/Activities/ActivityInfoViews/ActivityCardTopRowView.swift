//
//  ActivityCardTopRowView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct ActivityCardTopRowView: View {
	var activity: FullFeedActivityDTO

	var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let title = activity.title {
                    ActivityCardTitleView(activityTitle: title)
                }
                ActivityCardTimeView(activity: activity)
            }
            Spacer()
            ParticipantsImagesView(activity: activity)
        }
	}
}

struct ActivityCardTitleView: View {
	var activityTitle: String
	var body: some View {
		// TODO: make this title editable
        Text(activityTitle)
            .font(.onestBold(size: 24))
            .foregroundColor(.white)
	}
}

struct ActivityCardTimeView: View {
    @ObservedObject var viewModel: ActivityInfoViewModel
    
    init(activity: FullFeedActivityDTO) {
        self.viewModel = ActivityInfoViewModel(
            activity: activity, activityInfoType: .time)
    }
    
    var body: some View {
        Text(viewModel.activityInfoDisplayString)
            .font(.onestRegular(size: 14))
            .foregroundColor(.white.opacity(0.85))
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	ActivityCardTopRowView(activity: FullFeedActivityDTO.mockDinnerActivity).environmentObject(appCache)
}
