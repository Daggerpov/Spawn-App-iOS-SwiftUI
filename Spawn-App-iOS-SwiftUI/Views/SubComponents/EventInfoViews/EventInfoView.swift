//
//  EventInfoView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct EventInfoView: View {
	@ObservedObject var viewModel: EventInfoViewModel

	init(event: Event, eventInfoType: EventInfoType) {
		self.viewModel = EventInfoViewModel(
			event: event, eventInfoType: eventInfoType)
	}

	var body: some View {
		HStack(spacing: 5) {
			Image(systemName: viewModel.imageSystemName)
				.padding(5)
				.background(
					RoundedRectangle(cornerRadius: 30)
						.fill(Color.white.opacity(0.1))
				)

			Text(viewModel.eventInfoDisplayString)
				.lineLimit(1)
				.fixedSize()
				.font(.caption2)
				.padding(.horizontal, 3)
		}
		.padding(.trailing, 10)
		.overlay {
			// Background for the text bubble
			RoundedRectangle(cornerRadius: 30)
				.fill(Color.white.opacity(0.1))
				.frame(height: 30)
		}
		.fixedSize()

	}
}
