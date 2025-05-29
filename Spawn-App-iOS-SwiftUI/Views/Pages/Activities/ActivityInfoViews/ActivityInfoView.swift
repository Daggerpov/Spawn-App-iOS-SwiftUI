//
//  ActivityInfoView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-11-19.
//

import SwiftUI

struct ActivityInfoView: View {
	@ObservedObject var viewModel: ActivityInfoViewModel

	init(activity: FullFeedActivityDTO, activityInfoType: ActivityInfoType) {
		self.viewModel = ActivityInfoViewModel(
			activity: activity, activityInfoType: activityInfoType)
	}

	var body: some View {
		HStack {
			Image(systemName: viewModel.imageSystemName)
				.foregroundColor(.white)
				.font(.system(size: 14))
			
			VStack(alignment: .leading, spacing: 2) {
				Text(viewModel.activityInfoDisplayString)
					.foregroundColor(.white)
					.font(.caption)
					.bold()
			}
			
			Spacer()
		}
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @StateObject var appCache = AppCache.shared
	ActivityInfoView(activity: FullFeedActivityDTO.mockDinnerActivity, activityInfoType: ActivityInfoType.location).environmentObject(appCache)
}
