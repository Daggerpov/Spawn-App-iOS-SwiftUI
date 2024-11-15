//
//  EventTimeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct EventTimeView: View {
    @ObservedObject var viewModel: EventTimeViewModel
    
    init(event: Event) {
        self.viewModel = EventTimeViewModel(event: event)
    }
    
    var body: some View {
		// TODO: refactor this and `EventLocationView` into component;
		// lots of duplicate code and styling
		HStack(spacing: 5) {
			Image(systemName: "clock")
				.padding(5)
				.background(
					RoundedRectangle(cornerRadius: 30)
						.fill(Color.white.opacity(0.1))
				)

			Text(viewModel.eventTimeDisplayString)
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
    }
}
