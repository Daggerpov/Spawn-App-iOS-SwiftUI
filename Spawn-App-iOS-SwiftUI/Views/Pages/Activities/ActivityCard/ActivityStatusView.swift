//
//  ActivityStatusView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/14/25.
//

import SwiftUI

struct ActivityStatusView: View {
	let statusBadgeFontColor: Color = .black.opacity(0.8)
	@StateObject private var viewModel: ActivityStatusViewModel

	init(activity: FullFeedActivityDTO) {
		self._viewModel = StateObject(wrappedValue: ActivityStatusViewModel(activity: activity))
	}

	var body: some View {
		Text(viewModel.status.displayText)
			.font(.onestSemiBold(size: 11))
			.foregroundColor(statusBadgeFontColor)
			.padding(.horizontal, 12)
			.padding(.vertical, 6)
			.background(
				UnevenRoundedRectangle(
					topLeadingRadius: 8,
					bottomLeadingRadius: 2,
					bottomTrailingRadius: 14,
					topTrailingRadius: 2
				)
				.fill(viewModel.status.badgeColor)
			)
	}
}
