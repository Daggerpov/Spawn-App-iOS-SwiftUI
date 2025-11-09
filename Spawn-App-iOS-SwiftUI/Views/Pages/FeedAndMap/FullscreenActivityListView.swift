//
//  FullscreenActivityListView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Steve on 6/30/25.
//

import SwiftUI

struct FullscreenActivityListView: View {
	@ObservedObject var viewModel: FeedViewModel
	var user: BaseUserDTO
	var callback: (FullFeedActivityDTO, Color) -> Void
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		VStack {
			HStack {
				Button(action: {
					dismiss()
				}) {
					Image(systemName: "chevron.left")
						.foregroundColor(universalAccentColor)
				}
				.padding(.leading)
				Text("All Activities")
					.font(.onestSemiBold(size: 16))
					.foregroundColor(figmaBlack400)
				Spacer()
			}
			ActivityListView(viewModel: viewModel, user: user, callback: callback)
		}
		.padding(.top)
	}
}
