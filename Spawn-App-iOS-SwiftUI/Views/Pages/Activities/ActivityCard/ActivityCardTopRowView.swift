//
//  ActivityCardTopRowView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct ActivityCardTopRowView: View {
	@ObservedObject var activity: FullFeedActivityDTO
    let subtitleFontSize: CGFloat = 14
    let subtitleColor: Color = .white.opacity(0.85)
    let viewModel: ActivityInfoViewModel
    
    // Optional binding to control tab selection for current user navigation
    @Binding var selectedTab: TabType?
    
    init(activity: FullFeedActivityDTO, selectedTab: Binding<TabType?> = .constant(nil), locationManager: LocationManager) {
        self.activity = activity
        self.viewModel = ActivityInfoViewModel(activity: activity, locationManager: locationManager)
        self._selectedTab = selectedTab
    }

	var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let title = activity.title {
                    ActivityCardTitleView(activityTitle: title)
                }
                activitySubtitleView
            }
            Spacer()
            ParticipantsImagesView(activity: activity, selectedTab: $selectedTab, imageType: .feedCardParticipants)
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

extension ActivityCardTopRowView {
    var activitySubtitleView: some View {
        Text("By ")
            .font(.onestRegular(size: subtitleFontSize))
            .foregroundColor(subtitleColor) +
        Text(activity.creatorUser.name ?? activity.creatorUser.username ?? "User")
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
    @Previewable @StateObject var locationManager = LocationManager()
    ActivityCardTopRowView(activity: FullFeedActivityDTO.mockDinnerActivity, locationManager: locationManager).environmentObject(appCache)
}
