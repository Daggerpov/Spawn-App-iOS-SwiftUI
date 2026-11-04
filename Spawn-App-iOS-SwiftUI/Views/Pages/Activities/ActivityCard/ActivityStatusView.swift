//
//  ActivityStatusView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/14/25.
//

import SwiftUI

struct ActivityStatusView: View {
	let statusBadgeFontColor: Color = .black.opacity(0.8)
	@State private var viewModel: ActivityStatusViewModel

	init(activity: FullFeedActivityDTO) {
		self._viewModel = State(wrappedValue: ActivityStatusViewModel(activity: activity))
	}

	var body: some View {
		Text(viewModel.status.displayText)
			.font(.onestSemiBold(size: 11))
			.foregroundColor(statusBadgeFontColor)
			.lineLimit(1)
			.fixedSize()
			.padding(.horizontal, 12)
			.padding(.vertical, 8)  // same height as the location pill next to it
			.background(
				Capsule()
					.fill(viewModel.status.badgeColor)
			)
	}
}
