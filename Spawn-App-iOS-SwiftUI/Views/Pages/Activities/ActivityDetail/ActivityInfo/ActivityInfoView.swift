//
//  ActivityInfoView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-11-19.
//

import SwiftUI

struct ActivityInfoView: View {
	@ObservedObject var viewModel: ActivityInfoViewModel

	init(activity: FullFeedActivityDTO, activityInfoType: ActivityInfoType, locationManager: LocationManager) {
		self.viewModel = ActivityInfoViewModel(
			activity: activity, locationManager: locationManager)
	}

	var body: some View {
		HStack {
//			Image(systemName: viewModel.imageSystemName)
//				.foregroundColor(.white)
//				.font(.system(size: 14))
			
			VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.getDisplayString(activityInfoType: .location))
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
	@Previewable @ObservedObject var appCache = AppCache.shared
	ActivityInfoView(activity: FullFeedActivityDTO.mockDinnerActivity, activityInfoType: ActivityInfoType.location, locationManager: LocationManager.shared).environmentObject(appCache)
}
