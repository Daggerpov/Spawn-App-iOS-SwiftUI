//
//  EventLocationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct EventLocationView: View {
    var event: Event

    var body: some View {
        if let eventLocation = event.location?.locationName {
			// TODO: refactor this and `EventTimeView` into component;
			// lots of duplicate code and styling
			HStack(spacing: 5) {
				Image(systemName: "map")
					.padding(5)
					.background(
						RoundedRectangle(cornerRadius: 30)
							.fill(Color.white.opacity(0.1))
					)

				Text(eventLocation)
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
}
