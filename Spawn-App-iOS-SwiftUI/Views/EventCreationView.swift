//
//  EventCreationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct EventCreationView: View {
	@ObservedObject var viewModel: EventCreationViewModel

	init(creatingUser: User) {
		self.viewModel = EventCreationViewModel(creatingUser: creatingUser)
	}

	var body: some View {

		ScrollView {
			VStack(alignment: .leading, spacing: 20) {
				// Title and Time Information
				EventCardTitleView(eventTitle: "")

				HStack {
					VStack(alignment: .leading, spacing: 10) {
						EventInfoView(
							event: viewModel.event, eventInfoType: .time)
						EventInfoView(
							event: viewModel.event, eventInfoType: .location)
					}
					.foregroundColor(.white)

					Spacer()  // Ensures alignment but doesn't add spacing below the content
				}

				// Note
				if let note = viewModel.event.note {
					Text("Note: \(note)")
						.font(.body)
				}
			}
			.padding(20)
			.background(universalAccentColor)
			.cornerRadius(universalRectangleCornerRadius)
		}
		.padding(.horizontal)  // Reduces padding on the bottom
		.padding(.top, 200)
	}
}

#Preview {
	EventCreationView(creatingUser: .danielAgapov)
}
