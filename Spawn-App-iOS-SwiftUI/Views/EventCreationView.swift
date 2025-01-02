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
		VStack(spacing: 20) {
			TextField("Event Title", text: $viewModel.event.title)
				.font(.title2.bold())
				.foregroundColor(.primary)
				.padding()
				.background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))

			HStack {
				EventInputField(iconName: "clock", placeholder: "Start & End Time", value: $viewModel.event.time)
				EventInputField(iconName: "mappin.and.ellipse", placeholder: "Location", value: $viewModel.event.location)
			}

			EventInputField(iconName: "tag", placeholder: "Audience", value: $viewModel.event.audience)

			TextEditor(text: $viewModel.event.note)
				.padding()
				.frame(height: 80)
				.background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
				.overlay(
					RoundedRectangle(cornerRadius: 10)
						.stroke(Color(.systemGray4), lineWidth: 1)
				)
				.foregroundColor(.secondary)
				.cornerRadius(10)
				.overlay(alignment: .topTrailing) {
					Image(systemName: "pencil")
						.padding(8)
						.foregroundColor(.secondary)
				}

			Button(action: viewModel.createEvent) {
				Text("spawn")
					.font(.headline)
					.frame(maxWidth: .infinity)
					.padding()
					.background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor))
					.foregroundColor(.white)
			}
			.padding(.top, 20)
		}
		.padding()
		.background(Color(UIColor.systemBackground))
		.cornerRadius(15)
		.shadow(radius: 10)
		.padding(.horizontal, 20)
	}
}

struct EventInputField: View {
	var iconName: String
	var placeholder: String
	@Binding var value: String

	var body: some View {
		HStack {
			Image(systemName: iconName)
				.foregroundColor(.secondary)
			TextField(placeholder, text: $value)
				.foregroundColor(.primary)
		}
		.padding()
		.background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
	}
}


#Preview {
	EventCreationView(creatingUser: .danielAgapov)
}
