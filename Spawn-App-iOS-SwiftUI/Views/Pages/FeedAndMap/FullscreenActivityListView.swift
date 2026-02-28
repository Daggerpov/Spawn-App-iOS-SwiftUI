//
//  FullscreenActivityListView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Steve on 6/30/25.
//

import SwiftUI

struct FullscreenActivityListView: View {
	var viewModel: FeedViewModel
	var user: BaseUserDTO
	var callback: (FullFeedActivityDTO, Color) -> Void
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		VStack(spacing: 0) {
			// Header
			HStack {
				UnifiedBackButton {
					dismiss()
				}

				Spacer()

				Text("All Activities")
					.font(.onestSemiBold(size: 20))
					.foregroundColor(universalAccentColor)

				Spacer()

				// Invisible chevron to balance the back button
				Image(systemName: "chevron.left")
					.font(.system(size: 20, weight: .semibold))
					.foregroundColor(.clear)
			}
			.padding(.horizontal, screenEdgePadding)
			.padding(.vertical, 12)

			ActivityListView(viewModel: viewModel, user: user, callback: callback)
		}
	}
}
