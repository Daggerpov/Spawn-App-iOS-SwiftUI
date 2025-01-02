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
		VStack(alignment: .leading, spacing: 20) {
			TextField("Event Title", text: $viewModel.event.title)
				.font(.title2.bold())
				.foregroundColor(.primary)
				.padding()
				.background(
					RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6))
				)

			HStack(spacing: 16) {
				EventInputField(
					iconName: "clock", placeholder: "Start Time",
					value: $viewModel.event.startTime)
				EventInputField(
					iconName: "clock.arrow.circlepath", placeholder: "End Time",
					value: $viewModel.event.endTime)
			}

			EventInputField(
				iconName: "mappin.and.ellipse", placeholder: "Location",
				value: Binding(
					get: { viewModel.event.location?.name ?? "" },
					set: { viewModel.event.location?.name = $0 ?? "" }
				))

			TextEditor(
				text: Binding(
					get: { viewModel.event.note ?? "" },
					set: { viewModel.event.note = $0.isEmpty ? nil : $0 }
				)
			)
			.padding()
			.frame(height: 80)
			.background(
				RoundedRectangle(cornerRadius: 10).fill(
					Color(.systemGray6)
				)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 10)
					.stroke(Color(.systemGray4), lineWidth: 1)
			)
			.cornerRadius(10)

			Button(action: {
				// TODO DANIEL: create event action
				print("asd;lfkj")
			}) {
				Text("spawn")
					.font(.headline)
					.frame(maxWidth: .infinity)
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 10).fill(
							Color.accentColor)
					)
					.foregroundColor(.white)
			}
			.padding(.top, 20)
		}
		.padding()
		.background(universalBackgroundColor)
		.cornerRadius(15)
		.shadow(radius: 10)
		.padding(.horizontal, 20)
		.padding(.bottom, 200)
	}
}

struct EventInputField: View {
	var iconName: String
	var placeholder: String
	@Binding var value: String?

	var body: some View {
		HStack {
			Image(systemName: iconName)
				.foregroundColor(.secondary)
			TextField(
				placeholder,
				text: Binding(
					get: { value ?? "" },
					set: { value = $0 }
				)
			)
			.foregroundColor(.primary)
		}
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
	}
}

#Preview {
	EventCreationView(creatingUser: .danielAgapov)
}
