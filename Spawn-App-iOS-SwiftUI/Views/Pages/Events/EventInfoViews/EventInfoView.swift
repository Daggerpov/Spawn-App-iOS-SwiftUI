//
//  EventInfoView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct EventInfoView: View {
	@ObservedObject var viewModel: ActivityInfoViewModel

	init(event: FullFeedActivityDTO, eventInfoType: ActivityInfoType, locationManager: LocationManager) {
		self.viewModel = ActivityInfoViewModel(
			activity: event, locationManager: locationManager)
	}

	var body: some View {
		HStack {
			HStack(spacing: 5) {
				//				Image(systemName: viewModel.imageSystemName)
				//					.padding(5)
				//					.background(
				//						RoundedRectangle(cornerRadius: 30)
				//							.fill(Color.white.opacity(0.1))
				//					)

				Text(viewModel.getDisplayString(activityInfoType: .location))
					.lineLimit(1)
					.fixedSize()
					.font(.caption2)
					.padding(.horizontal, 3)
			}
			.padding(.trailing, 10)
			.overlay {
				// Background for the text bubble
				RoundedRectangle(cornerRadius: 30)
					.fill(universalBackgroundColor.opacity(0.1))
					.frame(height: 30)
			}
			.fixedSize()
		}

	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared
	EventInfoView(
		event: FullFeedActivityDTO.mockDinnerActivity, eventInfoType: ActivityInfoType.location,
		locationManager: LocationManager.shared
	).environmentObject(appCache)
}
